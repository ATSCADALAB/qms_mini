// lib/utils/helpers.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'constants.dart';
import 'dart:async'; // Thêm dòng này cho Timer
import 'dart:math';  // Thêm dòng này cho sqrt, pow
class AppHelpers {
  // ========== DATE & TIME HELPERS ==========

  /// Get current date in YYYY-MM-DD format
  static String getCurrentDate() {
    return DateTime.now().toIso8601String().split('T')[0];
  }

  /// Get current time in HH:MM:SS format
  static String getCurrentTime() {
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  /// Get current datetime in ISO format
  static String getCurrentDateTime() {
    return DateTime.now().toIso8601String();
  }

  /// Format datetime for display
  static String formatDateTime(DateTime dateTime, {String? format}) {
    return DateFormat(format ?? 'dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  /// Format date for display
  static String formatDate(DateTime dateTime, {String? format}) {
    return DateFormat(format ?? 'dd/MM/yyyy').format(dateTime);
  }

  /// Format time for display
  static String formatTime(DateTime dateTime, {String? format}) {
    return DateFormat(format ?? 'HH:mm:ss').format(dateTime);
  }

  /// Get time ago string (e.g., "2 phút trước")
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  // ========== STRING HELPERS ==========

  /// Generate random string with given length
  static String generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
        Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  /// Generate device ID
  static String generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = generateRandomString(4);
    return 'DEVICE_${timestamp}_$random';
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Clean and format phone number
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length >= 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return cleaned;
  }

  /// Mask sensitive data (e.g., passwords)
  static String maskSensitiveData(String data, {int visibleChars = 2}) {
    if (data.length <= visibleChars * 2) return '***';
    return '${data.substring(0, visibleChars)}${'*' * (data.length - visibleChars * 2)}${data.substring(data.length - visibleChars)}';
  }

  // ========== NUMBER HELPERS ==========

  /// Format number with leading zeros
  static String formatNumberWithLeadingZeros(int number, int digits) {
    return number.toString().padLeft(digits, '0');
  }

  /// Generate queue display number (e.g., A001, B025)
  static String generateQueueDisplayNumber(String prefix, int number) {
    return '$prefix${formatNumberWithLeadingZeros(number, 3)}';
  }

  /// Parse integer safely
  static int? parseIntSafely(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// Parse double safely
  static double? parseDoubleSafely(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }

  // ========== NETWORK HELPERS ==========

  /// Check internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Get network type
  static Future<String> getNetworkType() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile Data';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.none:
          return 'No Connection';
        default:
          return 'Unknown';
      }
    } catch (e) {
      return 'Error';
    }
  }

  /// Check if IP is in local network
  static bool isLocalIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);

    if (first == null || second == null) return false;

    // Check for private IP ranges
    return (first == 10) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168) ||
        (first == 127); // localhost
  }

  // ========== JSON HELPERS ==========

  /// Safely encode object to JSON
  static String safeJsonEncode(dynamic object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      debugPrint('JSON encode error: $e');
      return '{}';
    }
  }

  /// Safely decode JSON string
  static Map<String, dynamic>? safeJsonDecode(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('JSON decode error: $e');
      return null;
    }
  }

  /// Merge JSON objects
  static Map<String, dynamic> mergeJson(Map<String, dynamic> base, Map<String, dynamic> overlay) {
    final result = Map<String, dynamic>.from(base);
    overlay.forEach((key, value) {
      if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
        result[key] = mergeJson(result[key] as Map<String, dynamic>, value);
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  // ========== UI HELPERS ==========

  /// Show snackbar with message
  static void showSnackBar(BuildContext context, String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  /// Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.orange);
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message ?? 'Đang xử lý...')),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirmDialog(
      BuildContext context,
      String title,
      String content, {
        String confirmText = 'XÁC NHẬN',
        String cancelText = 'HỦY',
        Color? confirmColor,
      }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // ========== DEVICE HELPERS ==========

  /// Get device orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final size = getScreenSize(context);
    final diagonal = sqrt(pow(size.width, 2) + pow(size.height, 2));
    return diagonal > 1000; // Rough estimate for tablet size
  }

  // ========== QUEUE HELPERS ==========

  /// Calculate estimated wait time
  static int calculateEstimatedWaitTime(int queuePosition, {
    double averageServiceTimeMinutes = 3.0,
  }) {
    return (queuePosition * averageServiceTimeMinutes).ceil();
  }

  /// Get queue status color
  static Color getQueueStatusColor(String status) {
    final statusInfo = QueueStatus.getByValue(status.toLowerCase());
    if (statusInfo != null) {
      return Color(statusInfo['color'] as int);
    }
    return Colors.grey;
  }

  /// Format queue number for display
  static String formatQueueNumber(String prefix, int number) {
    return generateQueueDisplayNumber(prefix, number);
  }

  /// Generate next queue number
  static int getNextQueueNumber(List<int> existingNumbers) {
    if (existingNumbers.isEmpty) return 1;
    return existingNumbers.reduce(max) + 1;
  }

  // ========== SYSTEM HELPERS ==========

  /// Get app version info
  static Map<String, String> getAppVersionInfo() {
    return {
      'version': AppConstants.appVersion,
      'deviceType': AppConstants.deviceType,
      'platform': 'Android',
      'buildDate': getCurrentDate(),
    };
  }

  /// Log debug message with timestamp
  static void logDebug(String message, {String? tag}) {
    final timestamp = getCurrentTime();
    final tagStr = tag != null ? '[$tag]' : '';
    debugPrint('[$timestamp]$tagStr $message');
  }

  /// Log error with details
  static void logError(String message, dynamic error, {StackTrace? stackTrace}) {
    final timestamp = getCurrentTime();
    debugPrint('[$timestamp][ERROR] $message');
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Generate error report
  static Map<String, dynamic> generateErrorReport(dynamic error, StackTrace? stackTrace) {
    return {
      'timestamp': getCurrentDateTime(),
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'appVersion': AppConstants.appVersion,
      'deviceType': AppConstants.deviceType,
    };
  }

  // ========== UTILITY HELPERS ==========

  /// Debounce function calls
  static Timer? _debounceTimer;
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls
  static DateTime? _lastThrottleTime;
  static void throttle(Duration delay, VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || now.difference(_lastThrottleTime!) >= delay) {
      _lastThrottleTime = now;
      callback();
    }
  }

  /// Retry function with exponential backoff
  static Future<T> retryWithBackoff<T>(
      Future<T> Function() operation, {
        int maxRetries = 3,
        Duration initialDelay = const Duration(seconds: 1),
        double backoffFactor = 2.0,
      }) async {
    Duration delay = initialDelay;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;

        logDebug('Retry attempt ${attempt + 1} failed, waiting ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffFactor).round());
      }
    }

    throw Exception('All retry attempts failed');
  }

  /// Safe cast helper
  static T? safeCast<T>(dynamic value) {
    try {
      return value as T?;
    } catch (e) {
      return null;
    }
  }

  /// Generate unique ID
  static String generateUniqueId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${generateRandomString(6)}';
  }
}