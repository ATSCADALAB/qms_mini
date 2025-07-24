// lib/utils/validation_rules.dart
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
      static bool isValidIP(String ip) {
  if (!ipPattern.hasMatch(ip)) return false;

  // Additional check for valid IP ranges (0-255)
  final parts = ip.split('.');
  for (final part in parts) {
  final num = int.tryParse(part);
  if (num == null || num < 0 || num > 255) {
  return false;
  }
  }
  return true;
  }

  static bool isValidDomain(String domain) {
    if (domain.length < 3 || domain.length > 253) return false;
    return domainPattern.hasMatch(domain);
  }

  static bool isValidPort(int port) => port >= minPort && port <= maxPort;

  static bool isValidStoreId(String storeId) {
    if (storeId.length < 3 || storeId.length > maxStoreIdLength) return false;
    return storeIdPattern.hasMatch(storeId);
  }

  static bool isValidPrefix(String prefix) {
    if (prefix.isEmpty || prefix.length > maxPrefixLength) return false;
    return prefixPattern.hasMatch(prefix);
  }

  static bool isValidTime(String time) {
    return timePattern.hasMatch(time);
  }

  static bool isValidMqttBroker(String broker) {
    return isValidIP(broker) || isValidDomain(broker);
  }

  // Sanitization methods
  static String sanitizeStoreId(String input) {
    return input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_]'), '');
  }

  static String sanitizePrefix(String input) {
    return input.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
  }

  static String sanitizeIP(String input) {
    return input.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  // Format validation with detailed errors
  static ValidationResult validateStoreId(String storeId) {
    if (storeId.isEmpty) {
      return ValidationResult.error('Store ID không được để trống');
    }

    if (storeId.length < 3) {
      return ValidationResult.error('Store ID phải có ít nhất 3 ký tự');
    }

    if (storeId.length > maxStoreIdLength) {
      return ValidationResult.error('Store ID không được quá $maxStoreIdLength ký tự');
    }

    if (!storeIdPattern.hasMatch(storeId)) {
      return ValidationResult.error('Store ID chỉ được chứa chữ cái, số và dấu gạch dưới');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateMqttBroker(String broker) {
    if (broker.isEmpty) {
      return ValidationResult.error('MQTT Broker không được để trống');
    }

    if (isValidIP(broker)) {
      return ValidationResult.success();
    }

    if (isValidDomain(broker)) {
      return ValidationResult.success();
    }

    return ValidationResult.error('MQTT Broker phải là IP hoặc domain hợp lệ');
  }

  static ValidationResult validatePort(String portStr, String fieldName) {
    if (portStr.isEmpty) {
      return ValidationResult.error('$fieldName không được để trống');
    }

    final port = int.tryParse(portStr);
    if (port == null) {
      return ValidationResult.error('$fieldName phải là số');
    }

    if (!isValidPort(port)) {
      return ValidationResult.error('$fieldName phải từ $minPort-$maxPort');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateDeviceName(String name) {
    if (name.isEmpty) {
      return ValidationResult.error('Tên thiết bị không được để trống');
    }

    if (name.length > maxDeviceNameLength) {
      return ValidationResult.error('Tên thiết bị không được quá $maxDeviceNameLength ký tự');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateQueuePrefix(String prefix) {
    if (prefix.isEmpty) {
      return ValidationResult.error('Prefix không được để trống');
    }

    if (prefix.length > maxPrefixLength) {
      return ValidationResult.error('Prefix không được quá $maxPrefixLength ký tự');
    }

    if (!prefixPattern.hasMatch(prefix)) {
      return ValidationResult.error('Prefix chỉ được chứa chữ cái viết hoa');
    }

    return ValidationResult.success();
  }

  static ValidationResult validateResetTime(String time) {
    if (time.isEmpty) {
      return ValidationResult.success(); // Reset time is optional
    }

    if (!timePattern.hasMatch(time)) {
      return ValidationResult.error('Thời gian phải theo định dạng HH:MM');
    }

    return ValidationResult.success();
  }

  // Comprehensive configuration validation
  static List<ValidationResult> validateDeviceConfig({
    required String storeId,
    required String deviceName,
    required String mqttBroker,
    required String mqttPort,
    required String printerIP,
    required String printerPort,
    required String queuePrefix,
    required String startNumber,
    required String resetTime,
  }) {
    final results = <ValidationResult>[];

    results.add(validateStoreId(storeId));
    results.add(validateDeviceName(deviceName));
    results.add(validateMqttBroker(mqttBroker));
    results.add(validatePort(mqttPort, 'MQTT Port'));
    results.add(validateMqttBroker(printerIP)); // Using IP validation for printer
    results.add(validatePort(printerPort, 'Printer Port'));
    results.add(validateQueuePrefix(queuePrefix));
    results.add(validateResetTime(resetTime));

    // Validate start number
    final startNum = int.tryParse(startNumber);
    if (startNum == null || startNum < 1) {
      results.add(ValidationResult.error('Số bắt đầu phải lớn hơn 0'));
    } else {
      results.add(ValidationResult.success());
    }

    return results;
  }

  // Get only error messages
  static List<String> getValidationErrors({
    required String storeId,
    required String deviceName,
    required String mqttBroker,
    required String mqttPort,
    required String printerIP,
    required String printerPort,
    required String queuePrefix,
    required String startNumber,
    required String resetTime,
  }) {
    final results = validateDeviceConfig(
      storeId: storeId,
      deviceName: deviceName,
      mqttBroker: mqttBroker,
      mqttPort: mqttPort,
      printerIP: printerIP,
      printerPort: printerPort,
      queuePrefix: queuePrefix,
      startNumber: startNumber,
      resetTime: resetTime,
    );

    return results
        .where((result) => !result.isValid)
        .map((result) => result.message)
        .toList();
  }
}

class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult._(this.isValid, this.message);

  factory ValidationResult.success([String message = '']) {
    return ValidationResult._(true, message);
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(false, message);
  }

  @override
  String toString() => 'ValidationResult(isValid: $isValid, message: $message)';
}

// Error messages constants
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