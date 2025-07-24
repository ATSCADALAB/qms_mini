// lib/utils/constants.dart
class AppConstants {
  // App Info
  static const String appName = 'Queue Management System';
  static const String appVersion = '2.0.0';
  static const String deviceType = 'tablet1_print';

  // Configuration Keys
  static const String configKey = 'device_config';
  static const String storesKey = 'configured_stores';

  // Database
  static const String dbName = 'queue_management.db';
  static const int dbVersion = 2;

  // MQTT
  static const int mqttKeepAlive = 30;
  static const int mqttConnectTimeout = 10;
  static const int mqttReconnectDelay = 5;
  static const int mqttHeartbeatInterval = 30;

  // UI
  static const double tabletWidth = 1024.0;
  static const double tabletHeight = 600.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);

  // Queue Settings
  static const List<String> defaultPrefixes = ['A', 'B', 'C', 'VIP'];
  static const int maxQueueNumber = 999;
  static const int defaultStartNumber = 1;
  static const String defaultResetTime = '00:00';

  // Printer Settings
  static const List<String> printerTypes = ['thermal', 'laser', 'pos'];
  static const int defaultPrinterPort = 9100;
  static const int printTimeout = 10;

  // Status Values
  static const String statusWaiting = 'waiting';
  static const String statusServing = 'serving';
  static const String statusCalled = 'called';
  static const String statusCompleted = 'completed';
  static const String statusSkipped = 'skipped';
  static const String statusDeleted = 'deleted';

  // Priority Levels
  static const int priorityNormal = 0;
  static const int priorityHigh = 1;
  static const int priorityEmergency = 2;

  // Colors (Material Design)
  static const Map<String, int> colors = {
    'primary': 0xFF1976D2,
    'primaryDark': 0xFF0D47A1,
    'accent': 0xFF03DAC6,
    'success': 0xFF4CAF50,
    'warning': 0xFFFF9800,
    'error': 0xFFF44336,
    'info': 0xFF2196F3,
  };

  // Network
  static const int networkTimeout = 10;
  static const int maxRetries = 3;
  static const int retryDelay = 2;
}

class MqttTopics {
  // Topic templates
  static String queueAdd(String storeId) => 'queue/$storeId/add';
  static String queueCall(String storeId) => 'queue/$storeId/call';
  static String queuePriority(String storeId) => 'queue/$storeId/priority_call';
  static String queueDelete(String storeId) => 'queue/$storeId/delete';
  static String queueReset(String storeId) => 'queue/$storeId/reset';

  static String displayCurrent(String storeId) => 'display/$storeId/current_number';
  static String displayQueue(String storeId) => 'display/$storeId/queue_list';
  static String displayConfig(String storeId) => 'display/$storeId/config';

  static String systemStatus(String storeId) => 'system/$storeId/status';
  static String systemPause(String storeId) => 'system/$storeId/pause';
  static String systemResume(String storeId) => 'system/$storeId/resume';
  static String systemRestart(String storeId) => 'system/$storeId/restart';

  static String deviceHeartbeat(String storeId, String deviceType) =>
      'device/$storeId/$deviceType/heartbeat';
  static String deviceStatus(String storeId, String deviceType) =>
      'device/$storeId/$deviceType/status';
  static String deviceConfig(String storeId, String deviceType) =>
      'config/$storeId/$deviceType/+';

  static String syncRequest(String storeId) => 'sync/$storeId/request';
  static String syncResponse(String storeId) => 'sync/$storeId/response';
  static String syncBroadcast(String storeId) => 'sync/$storeId/broadcast';
}

class DatabaseTables {
  // Table names
  static const String queue = 'queue';
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

class ValidationRules {
  // Input validation patterns
  static final RegExp ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}');
      static final RegExp domainPattern = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+');
      static final RegExp storeIdPattern = RegExp(r'^[A-Z0-9_]{3,20}');
      static final RegExp prefixPattern = RegExp(r'^[A-Z]{1,3}');
      static final RegExp timePattern = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]');

      // Port ranges
      static const int minPort = 1;
      static const int maxPort = 65535;

      // String length limits
      static const int maxStoreIdLength = 20;
      static const int maxDeviceNameLength = 50;
      static const int maxPrefixLength = 3;
      static const int maxNotesLength = 255;

      // Validation methods
      static bool isValidIP(String ip) => ipPattern.hasMatch(ip);
  static bool isValidDomain(String domain) => domainPattern.hasMatch(domain);
  static bool isValidPort(int port) => port >= minPort && port <= maxPort;
  static bool isValidStoreId(String storeId) => storeIdPattern.hasMatch(storeId);
  static bool isValidPrefix(String prefix) => prefixPattern.hasMatch(prefix);
  static bool isValidTime(String time) => timePattern.hasMatch(time);
}

class ErrorMessages {
  // Configuration errors
  static const String emptyStoreId = 'Store ID không được để trống';
  static const String invalidStoreId = 'Store ID chỉ được chứa chữ cái, số và dấu gạch dưới';
  static const String emptyMqttBroker = 'MQTT Broker không được để trống';
  static const String invalidMqttBroker = 'MQTT Broker phải là IP hoặc domain hợp lệ';
  static const String invalidMqttPort = 'MQTT Port phải từ 1-65535';
  static const String emptyPrinterIP = 'IP máy in không được để trống';
  static const String invalidPrinterIP = 'IP máy in không hợp lệ';
  static const String invalidPrinterPort = 'Printer Port phải từ 1-65535';
  static const String emptyPrefix = 'Prefix không được để trống';
  static const String invalidPrefix = 'Prefix chỉ được chứa 1-3 chữ cái viết hoa';
  static const String invalidResetTime = 'Thời gian reset phải theo định dạng HH:MM';

  // Network errors
  static const String networkTimeout = 'Kết nối mạng timeout';
  static const String networkUnavailable = 'Không có kết nối mạng';
  static const String mqttConnectionFailed = 'Không thể kết nối MQTT Broker';
  static const String printerConnectionFailed = 'Không thể kết nối máy in';

  // Database errors
  static const String databaseError = 'Lỗi cơ sở dữ liệu';
  static const String saveConfigError = 'Không thể lưu cấu hình';
  static const String loadConfigError = 'Không thể tải cấu hình';

  // Queue errors
  static const String queueFull = 'Hàng đợi đã đầy';
  static const String duplicateNumber = 'Số thứ tự đã tồn tại';
  static const String invalidQueueNumber = 'Số thứ tự không hợp lệ';

  // Print errors
  static const String printError = 'Lỗi máy in';
  static const String printerNotReady = 'Máy in chưa sẵn sàng';
  static const String outOfPaper = 'Hết giấy in';
}

class SuccessMessages {
  static const String configSaved = 'Cấu hình đã được lưu thành công';
  static const String configLoaded = 'Đã tải cấu hình';
  static const String mqttConnected = 'Kết nối MQTT thành công';
  static const String printerConnected = 'Kết nối máy in thành công';
  static const String ticketPrinted = 'Đã in phiếu thành công';
  static const String queueReset = 'Đã reset hàng đợi';
  static const String syncCompleted = 'Đồng bộ dữ liệu hoàn tất';
}

class QueueStatus {
  static const List<Map<String, dynamic>> all = [
    {'value': 'waiting', 'label': 'Đang chờ', 'color': 0xFFFF9800},
    {'value': 'serving', 'label': 'Đang phục vụ', 'color': 0xFF2196F3},
    {'value': 'called', 'label': 'Đã gọi', 'color': 0xFF9C27B0},
    {'value': 'completed', 'label': 'Hoàn thành', 'color': 0xFF4CAF50},
    {'value': 'skipped', 'label': 'Bỏ qua', 'color': 0xFFF44336},
    {'value': 'deleted', 'label': 'Đã xóa', 'color': 0xFF9E9E9E},
  ];

  static Map<String, dynamic>? getByValue(String value) {
    try {
      return all.firstWhere((status) => status['value'] == value);
    } catch (e) {
      return null;
    }
  }
}

class PrinterSettings {
  // Thermal printer settings
  static const int thermalWidth = 48; // 48mm paper width
  static const int thermalDPI = 203;
  static const String thermalCodepage = 'CP1252';

  // Paper sizes
  static const Map<String, Map<String, int>> paperSizes = {
    '58mm': {'width': 384, 'chars': 32},
    '80mm': {'width': 576, 'chars': 48},
  };

  // Print settings
  static const int printDensity = 7;
  static const int printSpeed = 4;
  static const int cutType = 0; // 0=full cut, 1=partial cut
}

class DeviceInfo {
  static const String manufacturer = 'QMS';
  static const String model = 'Tablet Print Station';
  static const String platform = 'Android';
  static const List<String> supportedFeatures = [
    'MQTT',
    'SQLite',
    'Thermal Printer',
    'QR Scanner',
    'Network Discovery',
  ];
}