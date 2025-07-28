// lib/services/config_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_config.dart';
import '../utils/constants.dart';
import '../utils/validation_rules.dart';

class ConfigService extends ChangeNotifier {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  DeviceConfig? _config;
  bool _isLoaded = false;

  // Getters
  DeviceConfig? get config => _config;
  bool get isLoaded => _isLoaded;
  bool get hasConfig => _config != null;
  bool get isConfigValid => _config?.isValid ?? false;

  // Load configuration from storage
  Future<bool> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(AppConstants.configKey);

      if (configJson != null) {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        _config = DeviceConfig.fromMap(configMap);
        _isLoaded = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }

    _isLoaded = true;
    notifyListeners();
    return false;
  }

  // Save configuration
  Future<bool> saveConfig(DeviceConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(config.toMap());
      final success = await prefs.setString(AppConstants.configKey, configJson);

      if (success) {
        _config = config;
        _isLoaded = true;
        notifyListeners();

        // Also save to multi-store management
        await _saveToStoresList(config);

        return true;
      }
    } catch (e) {
      debugPrint('Error saving config: $e');
    }
    return false;
  }

  // Check if device is configured
  Future<bool> isConfigured() async {
    if (!_isLoaded) {
      await loadConfig();
    }
    return isConfigValid;
  }

  // Reset configuration
  Future<bool> resetConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.configKey);

      _config = null;
      _isLoaded = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resetting config: $e');
      return false;
    }
  }

  // Update specific setting
  Future<bool> updateSetting(String key, dynamic value) async {
    if (_config == null) return false;

    try {
      final configMap = _config!.toMap();
      configMap[key] = value;
      configMap['lastUpdated'] = DateTime.now().toIso8601String();

      final newConfig = DeviceConfig.fromMap(configMap);
      return await saveConfig(newConfig);
    } catch (e) {
      debugPrint('Error updating setting: $e');
      return false;
    }
  }

  // Update multiple settings at once
  Future<bool> updateSettings(Map<String, dynamic> updates) async {
    if (_config == null) return false;

    try {
      final configMap = _config!.toMap();
      updates.forEach((key, value) {
        configMap[key] = value;
      });
      configMap['lastUpdated'] = DateTime.now().toIso8601String();

      final newConfig = DeviceConfig.fromMap(configMap);
      return await saveConfig(newConfig);
    } catch (e) {
      debugPrint('Error updating settings: $e');
      return false;
    }
  }

  // ========== QR CODE IMPORT/EXPORT ==========

  // Export configuration to QR code
  String exportToQR() {
    if (_config == null) return '';
    return jsonEncode(_config!.toQRExport());
  }

  // Import configuration from QR code
  DeviceConfig? importFromQR(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;

      if (data['type'] != 'queue_management_config') {
        throw Exception('Invalid QR code type');
      }

      if (data['version'] != '2.0') {
        throw Exception('Unsupported config version: ${data['version']}');
      }

      return DeviceConfig.fromQRImport(
        data,
        deviceType: AppConstants.deviceType,
        deviceName: 'Imported Print Station',
      );
    } catch (e) {
      debugPrint('Error importing QR config: $e');
      return null;
    }
  }

  // ========== MULTI-STORE MANAGEMENT ==========

  // Save store to list of configured stores
  Future<void> _saveToStoresList(DeviceConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storesJson = prefs.getString(AppConstants.storesKey) ?? '[]';
      final List<dynamic> stores = jsonDecode(storesJson);

      // Check if store already exists
      final existingIndex = stores.indexWhere((s) => s['id'] == config.storeId);

      final storeData = {
        'id': config.storeId,
        'name': config.deviceName,
        'deviceType': config.deviceType,
        'lastUpdated': config.lastUpdated.toIso8601String(),
        'mqttBroker': config.mqttBroker,
        'isActive': true,
      };

      if (existingIndex >= 0) {
        stores[existingIndex] = storeData;
      } else {
        stores.add(storeData);
      }

      await prefs.setString(AppConstants.storesKey, jsonEncode(stores));
    } catch (e) {
      debugPrint('Error saving to stores list: $e');
    }
  }

  // Get list of configured stores
  Future<List<Map<String, dynamic>>> getConfiguredStores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storesJson = prefs.getString(AppConstants.storesKey) ?? '[]';
      final List<dynamic> stores = jsonDecode(storesJson);
      return stores.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting stores list: $e');
      return [];
    }
  }

  // Remove store from list
  Future<void> removeStore(String storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storesJson = prefs.getString(AppConstants.storesKey) ?? '[]';
      final List<dynamic> stores = jsonDecode(storesJson);

      stores.removeWhere((s) => s['id'] == storeId);
      await prefs.setString(AppConstants.storesKey, jsonEncode(stores));

      // Also remove specific store config if exists
      await prefs.remove('config_$storeId');
    } catch (e) {
      debugPrint('Error removing store: $e');
    }
  }

  // Switch to different store configuration
  Future<bool> switchStore(String storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('config_$storeId');

      if (configJson != null) {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        final config = DeviceConfig.fromMap(configMap);
        return await saveConfig(config);
      }
    } catch (e) {
      debugPrint('Error switching store: $e');
    }
    return false;
  }

  // ========== VALIDATION ==========

  // Validate current configuration
  List<String> validateConfig() {
    if (_config == null) {
      return ['Chưa có cấu hình'];
    }
    return _config!.validationErrors;
  }

  // Test MQTT connection settings
  Future<bool> testMqttConnection() async {
    if (_config == null) return false;

    try {
      // TODO: Implement actual MQTT connection test
      // For now, just validate the settings
      return _config!.mqttBroker.isNotEmpty &&
          _config!.mqttPort > 0 &&
          _config!.mqttPort <= 65535;
    } catch (e) {
      debugPrint('MQTT connection test error: $e');
      return false;
    }
  }

  // Test printer connection settings
  Future<bool> testPrinterConnection() async {
    if (_config == null) return false;

    try {
      // TODO: Implement actual printer connection test
      // For now, just validate the IP format
      return ValidationRules.isValidIP(_config!.printerIP) &&
          _config!.printerPort > 0 &&
          _config!.printerPort <= 65535;
    } catch (e) {
      debugPrint('Printer connection test error: $e');
      return false;
    }
  }

  // ========== HELPER METHODS ==========

  // Get connection strings for display
  String get mqttConnectionString {
    if (_config == null) return 'Not configured';
    return _config!.mqttConnectionString;
  }

  String get printerConnectionString {
    if (_config == null) return 'Not configured';
    return _config!.printerConnectionString;
  }

  // Get device info for heartbeat messages
  Map<String, dynamic> getDeviceInfo() {
    return {
      'deviceType': AppConstants.deviceType,
      'deviceName': _config?.deviceName ?? 'Unknown Device',
      'storeId': _config?.storeId ?? '',
      'version': AppConstants.appVersion,
      'platform': 'Android',
      'model': 'Tablet Print Station',
      'lastConfigUpdate': _config?.lastUpdated.toIso8601String() ?? '',
      'features': [
        'MQTT Communication',
        'SQLite Database',
        'Thermal Printer',
        'QR Code Scanner',
      ],
    };
  }

  // Get current queue settings
  Map<String, dynamic> getQueueSettings() {
    if (_config == null) return {};

    return {
      'prefix': _config!.queuePrefix,
      'startNumber': _config!.startNumber,
      'resetTime': _config!.resetTime,
    };
  }

  // Get MQTT topics for current configuration
  Map<String, String> getMqttTopics() {
    if (_config == null) return {};
    return _config!.topics;
  }

  // Check if configuration needs updating
  bool isConfigurationStale({Duration maxAge = const Duration(days: 30)}) {
    if (_config == null) return true;

    final now = DateTime.now();
    final configAge = now.difference(_config!.lastUpdated);

    return configAge > maxAge;
  }

  // Get configuration summary for display
  Map<String, String> getConfigSummary() {
    if (_config == null) {
      return {
        'Status': 'Not Configured',
        'Store ID': 'N/A',
        'Device': 'N/A',
        'MQTT': 'N/A',
        'Printer': 'N/A',
      };
    }

    return {
      'Status': _config!.isValid ? 'Configured' : 'Invalid',
      'Store ID': _config!.storeId,
      'Device': _config!.deviceName,
      'MQTT': _config!.mqttConnectionString,
      'Printer': _config!.printerConnectionString,
      'Queue': '${_config!.queuePrefix} from ${_config!.startNumber}',
      'Last Updated': _formatLastUpdated(_config!.lastUpdated),
    };
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // ========== BACKUP & RESTORE ==========

  // Export full configuration including settings
  Future<Map<String, dynamic>> exportFullConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'app_version': AppConstants.appVersion,
      'export_timestamp': DateTime.now().toIso8601String(),
      'device_config': _config?.toMap(),
      'stores_list': await getConfiguredStores(),
      'app_settings': {
        // Add any additional app settings here
      },
    };
  }

  // Import full configuration
  Future<bool> importFullConfiguration(Map<String, dynamic> data) async {
    try {
      // Validate import data
      if (data['app_version'] == null || data['device_config'] == null) {
        throw Exception('Invalid backup format');
      }

      // Import main device configuration
      if (data['device_config'] != null) {
        final config = DeviceConfig.fromMap(data['device_config']);
        await saveConfig(config);
      }

      // Import stores list
      if (data['stores_list'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.storesKey, jsonEncode(data['stores_list']));
      }

      return true;
    } catch (e) {
      debugPrint('Error importing configuration: $e');
      return false;
    }
  }

  // ========== DEBUG & LOGGING ==========

  // Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'config_loaded': _isLoaded,
      'has_config': hasConfig,
      'config_valid': isConfigValid,
      'config_age_hours': _config != null
          ? DateTime.now().difference(_config!.lastUpdated).inHours
          : null,
      'validation_errors': validateConfig(),
      'mqtt_connection': mqttConnectionString,
      'printer_connection': printerConnectionString,
    };
  }

  @override
  String toString() {
    return 'ConfigService{hasConfig: $hasConfig, isValid: $isConfigValid, storeId: ${_config?.storeId}}';
  }
}