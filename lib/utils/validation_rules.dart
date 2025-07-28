class ValidationRules {
  // Độ dài tối đa cho các trường văn bản
  static const int maxDeviceNameLength = 50;
  static const int maxPrefixLength = 5;

  // Biểu thức chính quy (Regex) để kiểm tra
  static final RegExp _ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
  static final RegExp _domainRegex = RegExp(r'^[a-zA-Z0-9.-]+$');
  static final RegExp _storeIdRegex = RegExp(r'^[A-Z0-9_]+$');
  static final RegExp _prefixRegex = RegExp(r'^[A-Z0-9]+$');
  static final RegExp _timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  // Các hàm kiểm tra
  static bool isValidIP(String ip) {
    return _ipRegex.hasMatch(ip);
  }

  static bool isValidDomain(String domain) {
    return _domainRegex.hasMatch(domain);
  }

  static bool isValidPort(int port) {
    return port > 0 && port <= 65535;
  }

  static bool isValidStoreId(String storeId) {
    return _storeIdRegex.hasMatch(storeId);
  }

  static bool isValidPrefix(String prefix) {
    return _prefixRegex.hasMatch(prefix) && prefix.length <= maxPrefixLength;
  }

  static bool isValidTime(String time) {
    return _timeRegex.hasMatch(time);
  }
}