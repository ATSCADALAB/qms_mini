// lib/models/mqtt_message.dart
import 'dart:convert';

enum MqttMessageType {
  queueAdd,
  queueCall,
  queuePriority,
  queueDelete,
  displayUpdate,
  systemStatus,
  deviceHeartbeat,
  configUpdate,
  syncRequest,
  syncResponse,
  unknown,
}

class MqttMessage {
  final String topic;
  final String rawPayload;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final MqttMessageType type;

  MqttMessage({
    required this.topic,
    required this.rawPayload,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
        type = _getMessageType(topic);

  // Create from MQTT message
  factory MqttMessage.fromMqtt({
    required String topic,
    required String payload,
  }) {
    Map<String, dynamic> parsedPayload = {};

    try {
      parsedPayload = jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      // If payload is not JSON, create a simple map
      parsedPayload = {'raw': payload};
    }

    return MqttMessage(
      topic: topic,
      rawPayload: payload,
      payload: parsedPayload,
    );
  }

  // Create queue add message
  factory MqttMessage.queueAdd({
    required String storeId,
    required int number,
    required String prefix,
    String operator = 'tablet1',
    String? notes,
  }) {
    final payload = {
      'action': 'add',
      'number': number,
      'prefix': prefix,
      'status': 'waiting',
      'priority': 0,
      'created_time': DateTime.now().toIso8601String(),
      'operator': operator,
      if (notes != null) 'notes': notes,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return MqttMessage(
      topic: 'queue/$storeId/add',
      rawPayload: jsonEncode(payload),
      payload: payload,
    );
  }

  // Create device heartbeat message
  factory MqttMessage.deviceHeartbeat({
    required String storeId,
    required String deviceType,
    required String deviceName,
    required Map<String, dynamic> status,
  }) {
    final payload = {
      'device_type': deviceType,
      'device_name': deviceName,
      'status': 'online',
      'timestamp': DateTime.now().toIso8601String(),
      'data': status,
    };

    return MqttMessage(
      topic: 'device/$storeId/$deviceType/heartbeat',
      rawPayload: jsonEncode(payload),
      payload: payload,
    );
  }

  // Create sync response message
  factory MqttMessage.syncResponse({
    required String storeId,
    required List<Map<String, dynamic>> queueData,
    required String requestId,
  }) {
    final payload = {
      'action': 'sync_response',
      'request_id': requestId,
      'device_type': 'tablet1',
      'queue_data': queueData,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return MqttMessage(
      topic: 'sync/$storeId/response',
      rawPayload: jsonEncode(payload),
      payload: payload,
    );
  }

  // Determine message type from topic
  static MqttMessageType _getMessageType(String topic) {
    final parts = topic.split('/');
    if (parts.length < 2) return MqttMessageType.unknown;

    final category = parts[0];
    final action = parts.length > 2 ? parts[2] : '';

    switch (category) {
      case 'queue':
        switch (action) {
          case 'add':
            return MqttMessageType.queueAdd;
          case 'call':
            return MqttMessageType.queueCall;
          case 'priority_call':
            return MqttMessageType.queuePriority;
          case 'delete':
            return MqttMessageType.queueDelete;
          default:
            return MqttMessageType.unknown;
        }
      case 'display':
        return MqttMessageType.displayUpdate;
      case 'system':
        return MqttMessageType.systemStatus;
      case 'device':
        return MqttMessageType.deviceHeartbeat;
      case 'config':
        return MqttMessageType.configUpdate;
      case 'sync':
        if (action == 'request') {
          return MqttMessageType.syncRequest;
        } else if (action == 'response') {
          return MqttMessageType.syncResponse;
        }
        return MqttMessageType.unknown;
      default:
        return MqttMessageType.unknown;
    }
  }

  // Check if message is for this store
  bool isForStore(String storeId) {
    return topic.contains('/$storeId/');
  }

  // Get store ID from topic
  String? get storeId {
    final parts = topic.split('/');
    if (parts.length >= 2) {
      return parts[1];
    }
    return null;
  }

  // Get device type from topic (for device messages)
  String? get deviceType {
    if (type == MqttMessageType.deviceHeartbeat) {
      final parts = topic.split('/');
      if (parts.length >= 3) {
        return parts[2];
      }
    }
    return null;
  }

  // Get action from payload
  String? get action => payload['action'] as String?;

  // Get timestamp from payload (fallback to message timestamp)
  DateTime get payloadTimestamp {
    final timestampStr = payload['timestamp'] as String?;
    if (timestampStr != null) {
      try {
        return DateTime.parse(timestampStr);
      } catch (e) {
        // Invalid timestamp, use message timestamp
      }
    }
    return timestamp;
  }

  // Validate message structure
  bool get isValid {
    switch (type) {
      case MqttMessageType.queueAdd:
        return payload.containsKey('number') &&
            payload.containsKey('prefix') &&
            payload.containsKey('operator');

      case MqttMessageType.queueCall:
      case MqttMessageType.queuePriority:
        return payload.containsKey('number') || payload.containsKey('action');

      case MqttMessageType.deviceHeartbeat:
        return payload.containsKey('device_type') &&
            payload.containsKey('status');

      case MqttMessageType.syncRequest:
        return payload.containsKey('request_id');

      case MqttMessageType.syncResponse:
        return payload.containsKey('request_id') &&
            payload.containsKey('queue_data');

      default:
        return true; // For other types, assume valid
    }
  }

  // Get display summary for debugging
  String get summary {
    switch (type) {
      case MqttMessageType.queueAdd:
        return 'New queue: ${payload['prefix']}${payload['number']}';
      case MqttMessageType.queueCall:
        return 'Call queue: ${payload['number'] ?? 'next'}';
      case MqttMessageType.queuePriority:
        return 'Priority call: ${payload['number']}';
      case MqttMessageType.deviceHeartbeat:
        return 'Heartbeat from ${payload['device_type']}';
      case MqttMessageType.syncRequest:
        return 'Sync request: ${payload['request_id']}';
      default:
        return 'MQTT: ${type.toString().split('.').last}';
    }
  }

  @override
  String toString() {
    return 'MqttMessage{topic: $topic, type: $type, timestamp: $timestamp}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MqttMessage &&
              runtimeType == other.runtimeType &&
              topic == other.topic &&
              rawPayload == other.rawPayload &&
              timestamp == other.timestamp;

  @override
  int get hashCode => topic.hashCode ^ rawPayload.hashCode ^ timestamp.hashCode;
}