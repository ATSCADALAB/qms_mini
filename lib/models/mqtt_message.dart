import 'dart:convert';
import '../utils/helpers.dart'; // Giả sử bạn có file này

/// Enum định nghĩa các loại message khác nhau trong hệ thống.
/// Sử dụng enum giúp code rõ ràng và tránh lỗi gõ sai chuỗi.
enum MqttMessageType {
  unknown,
  queueAdd,
  queueCall,
  queueDelete,
  queuePriority,
  deviceHeartbeat,
  deviceStatus,
  systemStatus,
  configUpdate,
  syncRequest,
  syncResponse,
}

/// Lớp đại diện cho một thông điệp MQTT hoàn chỉnh, có cấu trúc.
class MqttMessage {
  final String topic;
  final Map<String, dynamic> payload;
  final DateTime receivedAt;
  final MqttMessageType type;
  final String storeId;

  MqttMessage({
    required this.topic,
    required this.payload,
    required this.type,
    required this.storeId,
  }) : receivedAt = DateTime.now();

  // --- FACTORY CONSTRUCTORS ---

  /// **Hàm chính:** Tạo một MqttMessage từ topic và payload thô nhận được.
  /// Hàm này sẽ tự động phân tích topic để xác định loại message và storeId.
  factory MqttMessage.fromMqtt(String topic, String rawPayload) {
    final payloadMap = AppHelpers.safeJsonDecode(rawPayload) ?? {'raw': rawPayload};
    final parts = topic.split('/');
    final String storeId = (parts.length > 1 && parts[0] == 'store') ? parts[1] : '*';
    final MqttMessageType messageType = _getMessageTypeFromTopic(parts);

    return MqttMessage(
      topic: topic,
      payload: payloadMap,
      type: messageType,
      storeId: storeId,
    );
  }

  /// Tạo message "thêm số mới" để gửi đi.
  factory MqttMessage.queueAdd({
    required String storeId,
    required int number,
    required String prefix,
    String operator = 'kiosk',
    int priority = 0,
  }) {
    final topic = 'store/$storeId/queue/add';
    final payload = {
      'number': number,
      'prefix': prefix,
      'status': 'waiting',
      'priority': priority,
      'operator': operator,
      'timestamp': AppHelpers.getCurrentDateTime(),
    };
    return MqttMessage(topic: topic, payload: payload, type: MqttMessageType.queueAdd, storeId: storeId);
  }

  /// Tạo message "heartbeat" của thiết bị để gửi đi.
  factory MqttMessage.deviceHeartbeat({
    required String storeId,
    required String deviceType,
    required Map<String, dynamic> statusData,
  }) {
    final topic = 'store/$storeId/device/$deviceType/heartbeat';
    final payload = {
      'status': 'online',
      'data': statusData,
      'timestamp': AppHelpers.getCurrentDateTime(),
    };
    return MqttMessage(topic: topic, payload: payload, type: MqttMessageType.deviceHeartbeat, storeId: storeId);
  }

  /// Tạo message "phản hồi đồng bộ" để gửi đi.
  factory MqttMessage.syncResponse({
    required String storeId,
    required String requestId,
    required List<Map<String, dynamic>> queueData,
  }) {
    final topic = 'store/$storeId/sync/response';
    final payload = {
      'request_id': requestId,
      'queue_data': queueData,
      'timestamp': AppHelpers.getCurrentDateTime(),
    };
    return MqttMessage(topic: topic, payload: payload, type: MqttMessageType.syncResponse, storeId: storeId);
  }


  // --- GETTERS & HELPERS ---

  /// Lấy payload dưới dạng chuỗi JSON để gửi đi.
  String get rawPayload => jsonEncode(payload);

  /// Lấy timestamp từ payload, nếu không có thì dùng thời gian nhận message.
  DateTime get payloadTimestamp {
    final timestampStr = payload['timestamp'] as String?;
    if (timestampStr != null) {
      return DateTime.tryParse(timestampStr) ?? receivedAt;
    }
    return receivedAt;
  }

  /// Kiểm tra message có dành cho store hiện tại không.
  bool isForStore(String currentStoreId) {
    return storeId == currentStoreId || storeId == '*'; // '*' là wildcard cho tất cả store
  }

  /// **Điểm cải tiến:** Tóm tắt nội dung message một cách thông minh hơn để log.
  String get summary {
    final action = type.toString().split('.').last;
    final details = payload.containsKey('number')
        ? '${payload['prefix']}${payload['number']}'
        : payload.containsKey('request_id')
        ? payload['request_id']
        : '';
    return 'Action: $action ${details.isNotEmpty ? "($details)" : ""}';
  }

  /// **Điểm cải tiến:** Kiểm tra cấu trúc payload có hợp lệ không.
  bool get isValid {
    switch (type) {
      case MqttMessageType.queueAdd:
      case MqttMessageType.queueCall:
        return payload.containsKey('number') && payload.containsKey('prefix');
      case MqttMessageType.deviceHeartbeat:
        return payload.containsKey('status');
      case MqttMessageType.syncRequest:
        return payload.containsKey('request_id');
      case MqttMessageType.syncResponse:
        return payload.containsKey('request_id') && payload.containsKey('queue_data');
      default:
        return true; // Các loại khác mặc định là hợp lệ
    }
  }

  @override
  String toString() {
    return 'MqttMessage(type: $type, topic: $topic)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MqttMessage &&
              runtimeType == other.runtimeType &&
              topic == other.topic &&
              rawPayload == other.rawPayload;

  @override
  int get hashCode => topic.hashCode ^ rawPayload.hashCode;
}


/// **Hàm private, logic cốt lõi:**
/// Xác định loại message từ các phần của topic.
/// Cách này linh hoạt hơn, cho phép cấu trúc topic phức tạp.
MqttMessageType _getMessageTypeFromTopic(List<String> parts) {
  if (parts.length < 3) return MqttMessageType.unknown;

  final category = parts[2];
  final action = parts.length > 3 ? parts[3] : '';

  switch (category) {
    case 'queue':
      switch (action) {
        case 'add': return MqttMessageType.queueAdd;
        case 'call': return MqttMessageType.queueCall;
        case 'delete': return MqttMessageType.queueDelete;
        case 'priority': return MqttMessageType.queuePriority;
      }
      break;
    case 'sync':
      switch (action) {
        case 'request': return MqttMessageType.syncRequest;
        case 'response': return MqttMessageType.syncResponse;
      }
      break;
    case 'device':
      if (parts.length > 4) {
        switch (parts[4]) {
          case 'heartbeat': return MqttMessageType.deviceHeartbeat;
          case 'status': return MqttMessageType.deviceStatus;
        }
      }
      break;
    case 'system':
      if (action == 'status') return MqttMessageType.systemStatus;
      break;
    case 'config':
      if (action == 'update') return MqttMessageType.configUpdate;
      break;
  }

  return MqttMessageType.unknown;
}