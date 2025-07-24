// lib/models/device_config.dart
class DeviceConfig {
  final String deviceType;
  final String storeId;
  final String deviceName;

  // MQTT Settings
  final String mqttBroker;
  final int mqttPort;
  final String mqttUsername;
  final String mqttPassword;

  // Printer Settings
  final String printerIP;
  final int printerPort;
  final String printerType;

  // Queue Settings
  final String queuePrefix;
  final int startNumber;
  final String resetTime;

  // Additional settings
  final DateTime lastUpdated;

  DeviceConfig({
    required this.deviceType,
    required this.storeId,
    required this.deviceName,
    required this.mqttBroker,
    required this.mqttPort,
    required this.mqttUsername,
    required this.mqttPassword,
    required this.printerIP,
    required this.printerPort,
    required this.printerType,
    required this.queuePrefix,
    required this.startNumber,
    required this.resetTime,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'deviceType': deviceType,
      'storeId': storeId,
      'deviceName': deviceName,
      'mqttBroker': mqttBroker,
      'mqttPort': mqttPort,
      'mqttUsername': mqttUsername,
      'mqttPassword': mqttPassword,
      'printerIP': printerIP,
      'printerPort': printerPort,
      'printerType': printerType,
      'queuePrefix': queuePrefix,
      'startNumber': startNumber,
      'resetTime': resetTime,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from Map
  factory DeviceConfig.fromMap(Map<String, dynamic> map) {
    return DeviceConfig(
      deviceType: map['deviceType'] ?? 'tablet1_print',
      storeId: map['storeId'] ?? '',
      deviceName: map['deviceName'] ?? 'Tablet Print Station',
      mqttBroker: map['mqttBroker'] ?? '',
      mqttPort: map['mqttPort'] ?? 1883,
      mqttUsername: map['mqttUsername'] ?? '',
      mqttPassword: map['mqttPassword'] ?? '',
      printerIP: map['printerIP'] ?? '',
      printerPort: map['printerPort'] ?? 9100,
      printerType: map['printerType'] ?? 'thermal',
      queuePrefix: map['queuePrefix'] ?? 'A',
      startNumber: map['startNumber'] ?? 1,
      resetTime: map['resetTime'] ?? '00:00',
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
    );
  }

  // Generate MQTT topics for this device
  Map<String, String> get topics {
    return {
      // Publish topics (tablet1 gửi đi)
      'queue_add': 'queue/$storeId/add',
      'device_status': 'device/$storeId/tablet1/status',
      'device_heartbeat': 'device/$storeId/tablet1/heartbeat',
      'sync_response': 'sync/$storeId/response',

      // Subscribe topics (tablet1 nhận)
      'queue_call': 'queue/$storeId/call',
      'queue_priority': 'queue/$storeId/priority_call',
      'queue_delete': 'queue/$storeId/delete',
      'display_current': 'display/$storeId/current_number',
      'display_queue': 'display/$storeId/queue_list',
      'system_status': 'system/$storeId/status',
      'config_update': 'config/$storeId/tablet1/+',
      'sync_request': 'sync/$storeId/request',
    };
  }

  // Get specific topic by key
  String getTopic(String key) {
    return topics[key] ?? '';
  }

  // Copy with changes
  DeviceConfig copyWith({
    String? deviceType,
    String? storeId,
    String? deviceName,
    String? mqttBroker,
    int? mqttPort,
    String? mqttUsername,
    String? mqttPassword,
    String? printerIP,
    int? printerPort,
    String? printerType,
    String? queuePrefix,
    int? startNumber,
    String? resetTime,
    DateTime? lastUpdated,
  }) {
    return DeviceConfig(
      deviceType: deviceType ?? this.deviceType,
      storeId: storeId ?? this.storeId,
      deviceName: deviceName ?? this.deviceName,
      mqttBroker: mqttBroker ?? this.mqttBroker,
      mqttPort: mqttPort ?? this.mqttPort,
      mqttUsername: mqttUsername ?? this.mqttUsername,
      mqttPassword: mqttPassword ?? this.mqttPassword,
      printerIP: printerIP ?? this.printerIP,
      printerPort: printerPort ?? this.printerPort,
      printerType: printerType ?? this.printerType,
      queuePrefix: queuePrefix ?? this.queuePrefix,
      startNumber: startNumber ?? this.startNumber,
      resetTime: resetTime ?? this.resetTime,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  // Validation
  bool get isValid {
    return storeId.isNotEmpty &&
        mqttBroker.isNotEmpty &&
        printerIP.isNotEmpty &&
        queuePrefix.isNotEmpty;
  }

  // Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    if (storeId.isEmpty) {
      errors.add('Store ID không được để trống');
    }

    if (mqttBroker.isEmpty) {
      errors.add('MQTT Broker không được để trống');
    }

    if (printerIP.isEmpty) {
      errors.add('IP máy in không được để trống');
    }

    if (queuePrefix.isEmpty) {
      errors.add('Prefix không được để trống');
    }

    // Validate IP format
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (mqttBroker.isNotEmpty && !mqttBroker.contains('.') && !ipRegex.hasMatch(mqttBroker)) {
      errors.add('MQTT Broker phải là IP hoặc domain hợp lệ');
    }

    if (printerIP.isNotEmpty && !ipRegex.hasMatch(printerIP)) {
      errors.add('IP máy in không hợp lệ');
    }

    // Validate port ranges
    if (mqttPort < 1 || mqttPort > 65535) {
      errors.add('MQTT Port phải từ 1-65535');
    }

    if (printerPort < 1 || printerPort > 65535) {
      errors.add('Printer Port phải từ 1-65535');
    }

    return errors;
  }

  // Get connection strings for display
  String get mqttConnectionString => '$mqttBroker:$mqttPort';
  String get printerConnectionString => '$printerIP:$printerPort';

  // Export for QR code (sensitive data removed)
  Map<String, dynamic> toQRExport() {
    return {
      'type': 'queue_management_config',
      'version': '2.0',
      'storeId': storeId,
      'mqttBroker': mqttBroker,
      'mqttPort': mqttPort,
      'mqttUsername': mqttUsername,
      // Note: mqttPassword excluded for security
      'queuePrefix': queuePrefix,
      'startNumber': startNumber,
      'resetTime': resetTime,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Import from QR code
  factory DeviceConfig.fromQRImport(Map<String, dynamic> qrData, {
    required String deviceType,
    required String deviceName,
    String printerIP = '',
    int printerPort = 9100,
    String printerType = 'thermal',
    String mqttPassword = '',
  }) {
    return DeviceConfig(
      deviceType: deviceType,
      storeId: qrData['storeId'] ?? '',
      deviceName: deviceName,
      mqttBroker: qrData['mqttBroker'] ?? '',
      mqttPort: qrData['mqttPort'] ?? 1883,
      mqttUsername: qrData['mqttUsername'] ?? '',
      mqttPassword: mqttPassword, // Need to be entered manually
      printerIP: printerIP, // Need to be configured separately
      printerPort: printerPort,
      printerType: printerType,
      queuePrefix: qrData['queuePrefix'] ?? 'A',
      startNumber: qrData['startNumber'] ?? 1,
      resetTime: qrData['resetTime'] ?? '00:00',
    );
  }

  @override
  String toString() {
    return 'DeviceConfig{deviceType: $deviceType, storeId: $storeId, deviceName: $deviceName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DeviceConfig &&
              runtimeType == other.runtimeType &&
              deviceType == other.deviceType &&
              storeId == other.storeId &&
              deviceName == other.deviceName;

  @override
  int get hashCode => deviceType.hashCode ^ storeId.hashCode ^ deviceName.hashCode;
}