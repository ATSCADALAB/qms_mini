import 'package:flutter/material.dart';

// Hằng số chung của ứng dụng
import 'package:flutter/material.dart';

class AppConstants {
  // --- App Info ---
  static const String appName = 'QMS Mini Kiosk';
  static const String appVersion = '1.0.0';
  static const String deviceType = 'print_station';
  static const Duration animationDuration = Duration(milliseconds: 300);

  // --- Database ---
  static const String dbName = 'qms_mini.db';
  static const int dbVersion = 2;

  // --- SharedPreferences Keys ---
  static const String configKey = 'device_config';
  static const String storesKey = 'configured_stores';

  // --- MQTT Settings ---
  static const int mqttKeepAlive = 30; // Giây
  static const int mqttConnectTimeout = 10; // Giây
  static const int mqttHeartbeatInterval = 25; // Giây
  static const int mqttReconnectDelay = 5; // Giây
  static const int printTimeout = 5; // Giây
  static const double tabletWidth = 720; // Giây
  static const double tabletHeight = 1080; // Giây

  // --- Queue Status ---
  static const String statusWaiting = 'waiting';
  static const String statusCalled = 'called';
  static const String statusServing = 'serving';
  static const String statusCompleted = 'completed';
  static const String statusSkipped = 'skipped';
  static const String statusDeleted = 'deleted';

  // --- Queue Priority ---
  static const int priorityNormal = 0;
  static const int priorityMedium = 1;
  static const int priorityHigh = 2;

  // --- Bảng màu chính ---
  static const Map<String, int> colors = {
    'primary': 0xFF0D47A1,
    'secondary': 0xFF1565C0,
    'accent': 0xFF42A5F5,
  };
}

// Lớp chứa tên các bảng và cột trong CSDL
class DatabaseTables {
  // Table names
  static const String queue = 'queue_items';
  static const String callHistory = 'call_history';
  static const String systemSettings = 'system_settings';
  static const String deviceStatus = 'device_status';

  // Queue table columns
  static const String queueId = 'id';
  static const String queueNumber = 'number';
  static const String queuePrefix = 'prefix';
  static const String queueStatus = 'status';
  static const String queuePriority = 'priority';
  static const String queueCreatedDate = 'created_date';
  static const String queueCreatedTime = 'created_time';
  static const String queueCalledTime = 'called_time';
  static const String queueServedTime = 'served_time';
  static const String queueOperator = 'operator';
  static const String queueNotes = 'notes';
  static const String queueSynced = 'synced';
}

// Tập hợp các thông báo lỗi
class ErrorMessages {
  // Lỗi chung
  static const String saveConfigError = 'Lỗi khi lưu cấu hình';

  // Lỗi validation
  static const String emptyStoreId = 'Store ID không được để trống';
  static const String invalidStoreId = 'Store ID chỉ chứa chữ hoa, số và dấu gạch dưới';
  static const String emptyPrefix = 'Prefix không được để trống';
  static const String invalidPrefix = 'Prefix chỉ chứa chữ hoa và số';
  static const String invalidResetTime = 'Định dạng giờ không hợp lệ (HH:mm)';

  // Lỗi kết nối
  static const String emptyMqttBroker = 'MQTT Broker không được để trống';
  static const String invalidMqttBroker = 'MQTT Broker phải là IP hoặc domain hợp lệ';
  static const String invalidMqttPort = 'Port MQTT không hợp lệ';
  static const String emptyPrinterIP = 'IP Máy in không được để trống';
  static const String invalidPrinterIP = 'IP Máy in không hợp lệ';
  static const String invalidPrinterPort = 'Port Máy in không hợp lệ';

  // Lỗi khi test
  static const String mqttConnectionFailed = 'Kết nối MQTT thất bại';
  static const String printerConnectionFailed = 'Kết nối máy in thất bại';
}

// Tập hợp các thông báo thành công
class SuccessMessages {
  static const String configSaved = 'Cấu hình đã được lưu thành công!';
  static const String mqttConnected = 'Kết nối MQTT thành công!';
  static const String printerConnected = 'Kết nối máy in thành công!';
}

// Lớp quản lý trạng thái của hàng đợi
class QueueStatus {
  static const List<Map<String, dynamic>> statuses = [
    {
      'value': 'waiting',
      'name': 'Đang chờ',
      'color': 0xFFFFA726, // Orange
    },
    {
      'value': 'serving',
      'name': 'Đang phục vụ',
      'color': 0xFF42A5F5, // Blue
    },
    {
      'value': 'completed',
      'name': 'Hoàn thành',
      'color': 0xFF66BB6A, // Green
    },
    {
      'value': 'skipped',
      'name': 'Bỏ qua',
      'color': 0xFF78909C, // Blue Grey
    },
    {
      'value': 'cancelled',
      'name': 'Đã hủy',
      'color': 0xFFEF5350, // Red
    },
  ];

  /// Lấy thông tin trạng thái bằng giá trị (ví dụ: 'waiting')
  static Map<String, dynamic>? getByValue(String value) {
    try {
      return statuses.firstWhere((status) => status['value'] == value);
    } catch (e) {
      return null; // Trả về null nếu không tìm thấy
    }
  }
}