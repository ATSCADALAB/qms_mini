import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt; // Giữ nguyên tiền tố
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/device_config.dart';
import '../models/mqtt_message.dart'; // MqttMessage của chúng ta không cần tiền tố
import '../models/queue_item.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

// Enum này là của chúng ta, không bị ảnh hưởng
enum MqttConnectionState {
  disconnected,
  connecting,
  connected,
  error,
  reconnecting,
}

class MqttService extends ChangeNotifier {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;
  DeviceConfig? _config;

  MqttConnectionState _connectionState = MqttConnectionState.disconnected;
  String _lastError = '';
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  final StreamController<MqttMessage> _messageController =
  StreamController<MqttMessage>.broadcast();
  final StreamController<QueueItem> _queueUpdateController =
  StreamController<QueueItem>.broadcast();
  final StreamController<Map<String, dynamic>> _systemStatusController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _syncController =
  StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  MqttConnectionState get connectionState => _connectionState;
  String get lastError => _lastError;
  bool get isConnected => _connectionState == MqttConnectionState.connected;
  bool get isConnecting => _connectionState == MqttConnectionState.connecting;
  DeviceConfig? get config => _config;

  // Streams
  Stream<MqttMessage> get messageStream => _messageController.stream;
  Stream<QueueItem> get queueUpdates => _queueUpdateController.stream;
  Stream<Map<String, dynamic>> get systemStatus => _systemStatusController.stream;
  Stream<Map<String, dynamic>> get syncUpdates => _syncController.stream;

  // Initialize MQTT connection
  Future<bool> initialize(DeviceConfig config) async {
    _config = config;

    try {
      _setConnectionState(MqttConnectionState.connecting);

      final clientId =
          '${config.deviceType}_${config.storeId}_${AppHelpers.generateRandomString(4)}';
      _client = MqttServerClient(config.mqttBroker, clientId);

      _client!.port = config.mqttPort;
      _client!.keepAlivePeriod = AppConstants.mqttKeepAlive;
      _client!.connectTimeoutPeriod = AppConstants.mqttConnectTimeout * 1000;
      _client!.autoReconnect = false;
      _client!.logging(on: kDebugMode);

      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onSubscribeFail = _onSubscribeFail;
      _client!.onUnsubscribed = _onUnsubscribed;

      // ĐÃ SỬA: Thêm tiền tố `mqtt.`
      final connMessage = mqtt.MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(mqtt.MqttQos.atLeastOnce)
          .withWillMessage('Device disconnected unexpectedly')
          .withWillTopic(
          'device/${config.storeId}/${config.deviceType}/status');

      if (config.mqttUsername.isNotEmpty) {
        connMessage.authenticateAs(config.mqttUsername, config.mqttPassword);
      }

      _client!.connectionMessage = connMessage;

      await _client!.connect();

      // ĐÃ SỬA: Thêm tiền tố `mqtt.` để so sánh đúng enum của thư viện
      if (_client!.connectionStatus!.state == mqtt.MqttConnectionState.connected) {
        _setConnectionState(MqttConnectionState.connected);
        _setupMessageListener();
        _subscribeToTopics();
        _startHeartbeat();
        _reconnectAttempts = 0;
        AppHelpers.logDebug('MQTT connected successfully', tag: 'MQTT');
        return true;
      }

      _setConnectionState(MqttConnectionState.error);
      return false;
    } catch (e) {
      _lastError = e.toString();
      _setConnectionState(MqttConnectionState.error);
      AppHelpers.logError('MQTT connection failed', e);
      return false;
    }
  }

  // Disconnect from MQTT broker
  Future<void> disconnect() async {
    try {
      _stopHeartbeat();
      _stopReconnectTimer();

      // ĐÃ SỬA: Thêm tiền tố `mqtt.`
      if (_client?.connectionStatus?.state == mqtt.MqttConnectionState.connected) {
        await _publishDeviceStatus('offline');
        _client!.disconnect();
      }

      _setConnectionState(MqttConnectionState.disconnected);
      AppHelpers.logDebug('MQTT disconnected', tag: 'MQTT');
    } catch (e) {
      AppHelpers.logError('Error during MQTT disconnect', e);
    }
  }

  // Publish queue item addition
  Future<bool> publishQueueAdd(QueueItem queueItem) async {
    if (!isConnected || _config == null) return false;
    try {
      // Dùng MqttMessage của chúng ta, không cần tiền tố
      final message = MqttMessage.queueAdd(
        storeId: _config!.storeId,
        number: queueItem.number,
        prefix: queueItem.prefix,
        // priority: queueItem.priority, // Giả sử model MqttMessage có trường này
        operator: queueItem.operator,
      );
      return await _publishMessage(message.topic, message.rawPayload);
    } catch (e) {
      AppHelpers.logError('Failed to publish queue add', e);
      return false;
    }
  }

  // Publish device heartbeat
  Future<bool> publishHeartbeat(Map<String, dynamic> deviceInfo) async {
    if (!isConnected || _config == null) return false;
    try {
      final message = MqttMessage.deviceHeartbeat(
          storeId: _config!.storeId,
          deviceType: _config!.deviceType,
          statusData: deviceInfo);
      return await _publishMessage(message.topic, message.rawPayload);
    } catch (e) {
      AppHelpers.logError('Failed to publish heartbeat', e);
      return false;
    }
  }

  // Publish sync response
  Future<bool> publishSyncResponse(String requestId, List<QueueItem> queueData) async {
    if (!isConnected || _config == null) return false;

    try {
      final queueMaps = queueData.map((item) => item.toMqttPayload()).toList();
      final message = MqttMessage.syncResponse(
        storeId: _config!.storeId,
        queueData: queueMaps,
        requestId: requestId,
      );

      return await _publishMessage(message.topic, message.rawPayload);
    } catch (e) {
      AppHelpers.logError('Failed to publish sync response', e);
      return false;
    }
  }


  // Publish device status
  Future<bool> _publishDeviceStatus(String status) async {
    if (_config == null) return false;

    try {
      // Giả sử DeviceConfig có hàm getTopic
      final topic = _config!.getTopic('device_status');
      final payload = {
        'device_type': _config!.deviceType,
        'device_name': _config!.deviceName,
        'status': status,
        'timestamp': AppHelpers.getCurrentDateTime(),
        'connection_state': _connectionState.toString().split('.').last,
      };

      return await _publishMessage(topic, AppHelpers.safeJsonEncode(payload));
    } catch (e) {
      AppHelpers.logError('Failed to publish device status', e);
      return false;
    }
  }

  // Generic message publishing
  Future<bool> _publishMessage(String topic, String payload,
      {mqtt.MqttQos qos = mqtt.MqttQos.atLeastOnce}) async { // ĐÃ SỬA
    if (!isConnected || _client == null) return false;

    try {
      // ĐÃ SỬA: Thêm tiền tố `mqtt.`
      final builder = mqtt.MqttClientPayloadBuilder();
      builder.addString(payload);

      _client!.publishMessage(topic, qos, builder.payload!);

      AppHelpers.logDebug(
          'Published to $topic: ${AppHelpers.truncateText(payload, 100)}',
          tag: 'MQTT');
      return true;
    } catch (e) {
      AppHelpers.logError('Failed to publish message to $topic', e);
      return false;
    }
  }

  // Set up message listener
  void _setupMessageListener() {
    _client!.updates!.listen(
      // ĐÃ SỬA: Thêm tiền tố `mqtt.` vào cả hai
          (List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> messages) {
        for (final mqttMessage in messages) {
          _handleIncomingMessage(mqttMessage);
        }
      },
      onError: (error) {
        AppHelpers.logError('MQTT message listener error', error);
      },
    );
  }

  // Handle incoming MQTT messages
  void _handleIncomingMessage(mqtt.MqttReceivedMessage<mqtt.MqttMessage> mqttMessage) { // ĐÃ SỬA
    try {
      final topic = mqttMessage.topic;
      // ĐÃ SỬA: Thêm tiền tố `mqtt.`
      final payload = mqtt.MqttPublishPayload.bytesToStringAsString(
          (mqttMessage.payload as mqtt.MqttPublishMessage).payload.message);

      // Dùng MqttMessage của chúng ta
      final message = MqttMessage.fromMqtt(topic, payload);

      if (!message.isForStore(_config!.storeId)) {
        return;
      }

      AppHelpers.logDebug('Received: ${message.summary}', tag: 'MQTT');

      _messageController.add(message);
      _routeMessage(message);

    } catch (e) {
      AppHelpers.logError('Error handling incoming message', e);
    }
  }

  // Route messages to appropriate streams
  void _routeMessage(MqttMessage message) {
    try {
      switch (message.type) {
        case MqttMessageType.queueCall:
        case MqttMessageType.queuePriority:
        case MqttMessageType.queueDelete:
          _handleQueueUpdate(message);
          break;

        case MqttMessageType.systemStatus:
          _handleSystemStatus(message);
          break;

        case MqttMessageType.syncRequest:
          _handleSyncRequest(message);
          break;

        case MqttMessageType.syncResponse:
          _handleSyncResponse(message);
          break;

        case MqttMessageType.configUpdate:
          _handleConfigUpdate(message);
          break;

        default:
          break;
      }
    } catch (e) {
      AppHelpers.logError('Error routing message', e);
    }
  }

  // Handle queue update messages
  void _handleQueueUpdate(MqttMessage message) {
    try {
      if (message.payload.containsKey('number') &&
          message.payload.containsKey('prefix')) {
        final queueItem = QueueItem.fromMqttPayload(message.payload);
        _queueUpdateController.add(queueItem);
      }
    } catch (e) {
      AppHelpers.logError('Error handling queue update', e);
    }
  }

  // Handle system status messages
  void _handleSystemStatus(MqttMessage message) {
    try {
      _systemStatusController.add(message.payload);
    } catch (e) {
      AppHelpers.logError('Error handling system status', e);
    }
  }

  // Handle sync request messages
  void _handleSyncRequest(MqttMessage message) {
    try {
      _syncController.add({
        'type': 'sync_request',
        'request_id': message.payload['request_id'],
        'timestamp': message.payloadTimestamp,
      });
    } catch (e) {
      AppHelpers.logError('Error handling sync request', e);
    }
  }

  // Handle sync response messages
  void _handleSyncResponse(MqttMessage message) {
    try {
      _syncController.add({
        'type': 'sync_response',
        'request_id': message.payload['request_id'],
        'queue_data': message.payload['queue_data'],
        'timestamp': message.payloadTimestamp,
      });
    } catch (e) {
      AppHelpers.logError('Error handling sync response', e);
    }
  }

  // Handle config update messages
  void _handleConfigUpdate(MqttMessage message) {
    try {
      _systemStatusController.add({
        'type': 'config_update',
        'config': message.payload,
        'timestamp': message.payloadTimestamp,
      });
    } catch (e) {
      AppHelpers.logError('Error handling config update', e);
    }
  }

  // Subscribe to necessary topics
  void _subscribeToTopics() {
    if (!isConnected || _config == null) return;

    final topics = [
      _config!.getTopic('queue_call'),
      _config!.getTopic('queue_priority'),
      _config!.getTopic('queue_delete'),
      _config!.getTopic('system_status'),
      _config!.getTopic('config_update'),
      _config!.getTopic('sync_request'),
    ];

    for (final topic in topics) {
      if (topic.isNotEmpty) {
        _client!.subscribe(topic, mqtt.MqttQos.atLeastOnce); // ĐÃ SỬA
        AppHelpers.logDebug('Subscribed to: $topic', tag: 'MQTT');
      }
    }
  }

  // Start heartbeat timer
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: AppConstants.mqttHeartbeatInterval),
          (timer) => _sendHeartbeat(),
    );
  }

  // Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Send heartbeat
  Future<void> _sendHeartbeat() async {
    if (!isConnected || _config == null) return;
    try {
      final deviceInfo = {
        'last_seen': AppHelpers.getCurrentDateTime(),
        'connection_state': 'connected',
        'app_version': AppConstants.appVersion,
        'uptime': DateTime.now().millisecondsSinceEpoch,
      };
      await publishHeartbeat(deviceInfo);
    } catch (e) {
      AppHelpers.logError('Heartbeat failed', e);
    }
  }

  // Start reconnection timer
  void _startReconnectTimer() {
    _stopReconnectTimer();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppHelpers.logDebug('Max reconnect attempts reached', tag: 'MQTT');
      _setConnectionState(MqttConnectionState.error);
      return;
    }

    final delay = Duration(
        seconds: AppConstants.mqttReconnectDelay * (_reconnectAttempts + 1));
    AppHelpers.logDebug(
        'Reconnecting in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1})',
        tag: 'MQTT');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _attemptReconnect();
    });
  }

  // Stop reconnection timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Attempt to reconnect
  Future<void> _attemptReconnect() async {
    if (_config == null) return;

    AppHelpers.logDebug('Attempting reconnection...', tag: 'MQTT');
    _setConnectionState(MqttConnectionState.reconnecting);

    final success = await initialize(_config!);
    if (!success) {
      _startReconnectTimer();
    }
  }

  // Set connection state and notify listeners
  void _setConnectionState(MqttConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      notifyListeners();
      AppHelpers.logDebug(
          'Connection state: ${state.toString().split('.').last}',
          tag: 'MQTT');
    }
  }

  // MQTT event callbacks
  void _onConnected() {
    AppHelpers.logDebug('MQTT broker connected', tag: 'MQTT');
  }

  void _onDisconnected() {
    AppHelpers.logDebug('MQTT broker disconnected', tag: 'MQTT');
    _stopHeartbeat();

    if (_connectionState != MqttConnectionState.disconnected) {
      _setConnectionState(MqttConnectionState.disconnected);
      _startReconnectTimer();
    }
  }

  void _onSubscribed(String topic) {
    AppHelpers.logDebug('Subscribed to: $topic', tag: 'MQTT');
  }

  void _onSubscribeFail(String topic) {
    AppHelpers.logError('Failed to subscribe to: $topic', 'Subscription failed');
  }

  void _onUnsubscribed(String? topic) {
    AppHelpers.logDebug('Unsubscribed from: $topic', tag: 'MQTT');
  }

  // Test MQTT connection
  static Future<bool> testConnection({
    required String broker,
    required int port,
    String? username,
    String? password,
    int timeoutSeconds = 10,
  }) async {
    try {
      final testClient = MqttServerClient(broker, 'test_${AppHelpers.generateRandomString(6)}');
      testClient.port = port;
      testClient.connectTimeoutPeriod = timeoutSeconds * 1000;
      testClient.logging(on: false);

      final connMessage = mqtt.MqttConnectMessage() // ĐÃ SỬA
          .withClientIdentifier(testClient.clientIdentifier)
          .startClean();

      if (username?.isNotEmpty == true) {
        connMessage.authenticateAs(username!, password ?? '');
      }

      testClient.connectionMessage = connMessage;

      await testClient.connect();

      final isConnected = // ĐÃ SỬA
      testClient.connectionStatus?.state == mqtt.MqttConnectionState.connected;

      if (isConnected) {
        testClient.disconnect();
      }

      return isConnected;
    } catch (e) {
      AppHelpers.logError('MQTT test connection failed', e);
      return false;
    }
  }

  // Get connection info for debugging
  Map<String, dynamic> getConnectionInfo() {
    return {
      'state': _connectionState.toString().split('.').last,
      'last_error': _lastError,
      'reconnect_attempts': _reconnectAttempts,
      'client_id': _client?.clientIdentifier,
      'broker': _config?.mqttBroker,
      'port': _config?.mqttPort,
      'is_heartbeat_active': _heartbeatTimer?.isActive ?? false,
      'is_reconnect_timer_active': _reconnectTimer?.isActive ?? false,
    };
  }

  // Cleanup resources
  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _queueUpdateController.close();
    _systemStatusController.close();
    _syncController.close();
    super.dispose();
  }
}

// MQTT Connection Manager for easier usage
class MqttConnectionManager {
  static MqttService? _service;

  static Future<bool> initialize(DeviceConfig config) async {
    _service = MqttService();
    return await _service!.initialize(config);
  }

  static MqttService? get instance => _service;

  static bool get isConnected => _service?.isConnected ?? false;

  static Future<void> disconnect() async {
    await _service?.disconnect();
    _service = null;
  }

  static Future<bool> publishQueueAdd(QueueItem queueItem) async {
    return await _service?.publishQueueAdd(queueItem) ?? false;
  }

  static Stream<QueueItem>? get queueUpdates => _service?.queueUpdates;

  static Stream<Map<String, dynamic>>? get systemStatus => _service?.systemStatus;
}