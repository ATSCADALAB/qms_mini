// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // --- App Info ---
  static const String appName = 'QMS Mini Print Station';
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

  // --- Screen Dimensions for Tablets ---
  static const double tabletWidth = 1080; // Landscape width
  static const double tabletHeight = 720;  // Landscape height

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
    'primary': 0xFF0D47A1,         // Blue 800
    'primaryDark': 0xFF01579B,     // Blue 900
    'secondary': 0xFF1565C0,       // Blue 700
    'accent': 0xFF42A5F5,          // Blue 400
    'success': 0xFF4CAF50,         // Green 500
    'warning': 0xFFFF9800,         // Orange 500
    'error': 0xFFE53935,           // Red 600
    'info': 0xFF2196F3,            // Blue 500
  };

  // --- UI Constants ---
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 48.0;
  static const double iconSize = 24.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  // --- Font Sizes ---
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeXLarge = 24.0;
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
  static const String ticketPrinted = 'In phiếu thành công!';
  static const String queueReset = 'Reset hàng đợi thành công!';
}

// Lớp quản lý trạng thái của hàng đợi
class QueueStatus {
  static const List<Map<String, dynamic>> statuses = [
    {
      'value': AppConstants.statusWaiting,
      'name': 'Đang chờ',
      'color': 0xFFFFA726, // Orange
      'icon': Icons.hourglass_empty,
    },
    {
      'value': AppConstants.statusCalled,
      'name': 'Đã gọi',
      'color': 0xFF5C6BC0, // Indigo
      'icon': Icons.campaign,
    },
    {
      'value': AppConstants.statusServing,
      'name': 'Đang phục vụ',
      'color': 0xFF42A5F5, // Blue
      'icon': Icons.support_agent,
    },
    {
      'value': AppConstants.statusCompleted,
      'name': 'Hoàn thành',
      'color': 0xFF66BB6A, // Green
      'icon': Icons.check_circle,
    },
    {
      'value': AppConstants.statusSkipped,
      'name': 'Bỏ qua',
      'color': 0xFF78909C, // Blue Grey
      'icon': Icons.skip_next,
    },
    {
      'value': AppConstants.statusDeleted,
      'name': 'Đã xóa',
      'color': 0xFFEF5350, // Red
      'icon': Icons.delete,
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

  /// Lấy màu theo trạng thái
  static Color getColorByValue(String value) {
    final status = getByValue(value);
    if (status != null) {
      return Color(status['color'] as int);
    }
    return Colors.grey;
  }

  /// Lấy icon theo trạng thái
  static IconData getIconByValue(String value) {
    final status = getByValue(value);
    if (status != null) {
      return status['icon'] as IconData;
    }
    return Icons.help_outline;
  }
}

// Device Types for multi-device system
class DeviceTypes {
  static const String printStation = 'print_station';
  static const String callStation = 'call_station';
  static const String tvDisplay = 'tv_display';

  static const List<Map<String, dynamic>> types = [
    {
      'value': printStation,
      'name': 'Máy In Phiếu',
      'description': 'Thiết bị in phiếu số thứ tự',
      'icon': Icons.print,
    },
    {
      'value': callStation,
      'name': 'Máy Gọi Số',
      'description': 'Thiết bị điều khiển gọi số',
      'icon': Icons.campaign,
    },
    {
      'value': tvDisplay,
      'name': 'Màn Hình TV',
      'description': 'Hiển thị số đang phục vụ',
      'icon': Icons.tv,
    },
  ];
}

// MQTT Topic Templates
class MqttTopics {
  static const String queueAdd = 'queue/{storeId}/add';
  static const String queueCall = 'queue/{storeId}/call';
  static const String queuePriority = 'queue/{storeId}/priority';
  static const String queueDelete = 'queue/{storeId}/delete';
  static const String queueStatus = 'queue/{storeId}/status';

  static const String displayCurrent = 'display/{storeId}/current';
  static const String displayQueue = 'display/{storeId}/queue';
  static const String displayConfig = 'display/{storeId}/config';

  static const String systemStatus = 'system/{storeId}/status';
  static const String systemConfig = 'system/{storeId}/config';

  static const String deviceHeartbeat = 'device/{storeId}/{deviceType}/heartbeat';
  static const String deviceStatus = 'device/{storeId}/{deviceType}/status';

  static const String syncRequest = 'sync/{storeId}/request';
  static const String syncResponse = 'sync/{storeId}/response';

  /// Replace placeholders in topic template
  static String formatTopic(String template, {
    required String storeId,
    String? deviceType,
  }) {
    String topic = template.replaceAll('{storeId}', storeId);
    if (deviceType != null) {
      topic = topic.replaceAll('{deviceType}', deviceType);
    }
    return topic;
  }
}

// Validation Constants
class ValidationConstants {
  static const int maxStoreIdLength = 20;
  static const int maxDeviceNameLength = 50;
  static const int maxPrefixLength = 5;
  static const int maxNotesLength = 255;

  static const int minPort = 1;
  static const int maxPort = 65535;

  static const int defaultMqttPort = 1883;
  static const int defaultPrinterPort = 9100;
}

// App Features Configuration
class AppFeatures {
  static const bool enableQRCodeConfig = true;
  static const bool enableMultiStore = true;
  static const bool enablePrinterTest = true;
  static const bool enableAutoReset = true;
  static const bool enableAnalytics = true;
  static const bool enableVoiceAnnouncement = false; // For call station
  static const bool enablePriorityQueue = true;
  static const bool enableCustomPrefix = true;
}