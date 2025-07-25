// lib/services/printer_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/device_config.dart';
import '../models/queue_item.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

enum PrinterStatus {
  disconnected,
  connecting,
  connected,
  printing,
  error,
  outOfPaper,
  ready,
}

enum PrinterType {
  thermal,
  laser,
  pos,
}

class PrinterService extends ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  DeviceConfig? _config;
  Socket? _socket;
  PrinterStatus _status = PrinterStatus.disconnected;
  String _lastError = '';
  Timer? _connectionTimer;
  int _printJobCounter = 0;

  // Getters
  PrinterStatus get status => _status;
  String get lastError => _lastError;
  bool get isConnected => _status == PrinterStatus.connected || _status == PrinterStatus.ready;
  bool get isPrinting => _status == PrinterStatus.printing;
  bool get isReady => _status == PrinterStatus.ready;
  DeviceConfig? get config => _config;

  // Initialize printer connection
  Future<bool> initialize(DeviceConfig config) async {
    _config = config;

    try {
      _setStatus(PrinterStatus.connecting);

      // Create socket connection
      _socket = await Socket.connect(
        config.printerIP,
        config.printerPort,
        timeout: Duration(seconds: AppConstants.printTimeout),
      );

      // Set up socket listeners
      _socket!.listen(
        _onData,
        onError: _onError,
        onDone: _onDisconnected,
      );

      _setStatus(PrinterStatus.connected);
      AppHelpers.logDebug('Printer connected: ${config.printerConnectionString}', tag: 'PRINTER');

      // Test printer with status check
      final isReady = await _checkPrinterStatus();
      if (isReady) {
        _setStatus(PrinterStatus.ready);
        return true;
      }

      return true; // Connected but status unknown

    } catch (e) {
      _lastError = e.toString();
      _setStatus(PrinterStatus.error);
      AppHelpers.logError('Printer connection failed', e);
      return false;
    }
  }

  // Disconnect from printer
  Future<void> disconnect() async {
    try {
      _connectionTimer?.cancel();
      await _socket?.close();
      _socket = null;
      _setStatus(PrinterStatus.disconnected);
      AppHelpers.logDebug('Printer disconnected', tag: 'PRINTER');
    } catch (e) {
      AppHelpers.logError('Error during printer disconnect', e);
    }
  }

  // Print queue ticket
  Future<bool> printTicket(QueueItem queueItem, DeviceConfig config) async {
    if (!isConnected) {
      _lastError = 'Printer not connected';
      return false;
    }

    try {
      _setStatus(PrinterStatus.printing);
      _printJobCounter++;

      AppHelpers.logDebug('Printing ticket: ${queueItem.displayNumber}', tag: 'PRINTER');

      // Generate print data based on printer type
      Uint8List printData;
      switch (config.printerType) {
        case 'thermal':
          printData = _generateThermalTicket(queueItem, config);
          break;
        case 'laser':
        case 'pos':
          printData = _generateTextTicket(queueItem, config);
          break;
        default:
          printData = _generateThermalTicket(queueItem, config);
      }

      // Send data to printer
      _socket!.add(printData);
      await _socket!.flush();

      // Wait for printing to complete
      await Future.delayed(const Duration(seconds: 2));

      _setStatus(PrinterStatus.ready);
      AppHelpers.logDebug('Ticket printed successfully: ${queueItem.displayNumber}', tag: 'PRINTER');
      return true;

    } catch (e) {
      _lastError = e.toString();
      _setStatus(PrinterStatus.error);
      AppHelpers.logError('Print job failed', e);
      return false;
    }
  }

  // Print test page
  Future<bool> printTest(DeviceConfig config) async {
    if (!isConnected) {
      _lastError = 'Printer not connected';
      return false;
    }

    try {
      _setStatus(PrinterStatus.printing);

      AppHelpers.logDebug('Printing test page', tag: 'PRINTER');

      // Create test queue item
      final testItem = QueueItem(
        number: 999,
        prefix: 'TEST',
        status: 'test',
        createdDate: DateTime.now(),
        createdTime: DateTime.now(),
        operator: 'system',
        notes: 'Test print',
      );

      // Generate test print data
      final printData = _generateTestTicket(testItem, config);

      // Send data to printer
      _socket!.add(printData);
      await _socket!.flush();

      // Wait for printing to complete
      await Future.delayed(const Duration(seconds: 2));

      _setStatus(PrinterStatus.ready);
      AppHelpers.logDebug('Test page printed successfully', tag: 'PRINTER');
      return true;

    } catch (e) {
      _lastError = e.toString();
      _setStatus(PrinterStatus.error);
      AppHelpers.logError('Test print failed', e);
      return false;
    }
  }

  // Generate thermal printer ticket (ESC/POS commands)
  Uint8List _generateThermalTicket(QueueItem queueItem, DeviceConfig config) {
    final List<int> bytes = [];

    // ESC/POS Commands
    const esc = 0x1B;
    const gs = 0x1D;

    // Initialize printer
    bytes.addAll([esc, 0x40]); // ESC @ - Initialize

    // Set code page
    bytes.addAll([esc, 0x74, 0x00]); // ESC t 0 - Code page 437

    // Center alignment
    bytes.addAll([esc, 0x61, 0x01]); // ESC a 1 - Center alignment

    // Store name (large font)
    bytes.addAll([esc, 0x21, 0x30]); // ESC ! 48 - Double width and height
    bytes.addAll(utf8.encode(config.storeId));
    bytes.addAll([0x0A, 0x0A]); // LF LF

    // Reset font size
    bytes.addAll([esc, 0x21, 0x00]); // ESC ! 0 - Normal font

    // Title
    bytes.addAll([esc, 0x21, 0x08]); // ESC ! 8 - Emphasized
    bytes.addAll(utf8.encode('PHIẾU SỐ THỨ TỰ'));
    bytes.addAll([0x0A, 0x0A]); // LF LF

    // Reset emphasis
    bytes.addAll([esc, 0x21, 0x00]); // ESC ! 0 - Normal font

    // Queue number (extra large)
    bytes.addAll([gs, 0x21, 0x33]); // GS ! 51 - 4x width, 4x height
    bytes.addAll(utf8.encode(queueItem.displayNumber));
    bytes.addAll([0x0A, 0x0A, 0x0A]); // LF LF LF

    // Reset font size
    bytes.addAll([gs, 0x21, 0x00]); // GS ! 0 - Normal size

    // Date and time
    bytes.addAll([esc, 0x61, 0x00]); // ESC a 0 - Left alignment
    final dateTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(queueItem.createdTime);
    bytes.addAll(utf8.encode('Ngày: $dateTime'));
    bytes.addAll([0x0A]); // LF

    // Operator
    bytes.addAll(utf8.encode('Thiết bị: ${config.deviceName}'));
    bytes.addAll([0x0A]); // LF

    // Priority if applicable
    if (queueItem.priority > 0) {
      bytes.addAll([esc, 0x21, 0x08]); // ESC ! 8 - Emphasized
      bytes.addAll(utf8.encode('*** ƯU TIÊN ***'));
      bytes.addAll([esc, 0x21, 0x00]); // ESC ! 0 - Normal font
      bytes.addAll([0x0A]); // LF
    }

    // Notes if available
    if (queueItem.notes?.isNotEmpty == true) {
      bytes.addAll(utf8.encode('Ghi chú: ${queueItem.notes}'));
      bytes.addAll([0x0A]); // LF
    }

    // Separator line
    bytes.addAll([0x0A]); // LF
    bytes.addAll([esc, 0x61, 0x01]); // ESC a 1 - Center alignment
    bytes.addAll(utf8.encode('=' * 32));
    bytes.addAll([0x0A]); // LF

    // Footer message
    bytes.addAll(utf8.encode('Vui lòng chờ được gọi'));
    bytes.addAll([0x0A]); // LF
    bytes.addAll(utf8.encode('Cảm ơn quý khách!'));
    bytes.addAll([0x0A, 0x0A, 0x0A]); // LF LF LF

    // Cut paper (if supported)
    bytes.addAll([gs, 0x56, 0x00]); // GS V 0 - Full cut

    return Uint8List.fromList(bytes);
  }

  // Generate text ticket for laser/inkjet printers
  Uint8List _generateTextTicket(QueueItem queueItem, DeviceConfig config) {
    final StringBuffer buffer = StringBuffer();

    // Header
    buffer.writeln('=' * 40);
    buffer.writeln(config.storeId.toUpperCase());
    buffer.writeln('PHIẾU SỐ THỨ TỰ');
    buffer.writeln('=' * 40);
    buffer.writeln();

    // Queue number
    buffer.writeln('SỐ THỨ TỰ: ${queueItem.displayNumber}');
    buffer.writeln();

    // Details
    final dateTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(queueItem.createdTime);
    buffer.writeln('Ngày: $dateTime');
    buffer.writeln('Thiết bị: ${config.deviceName}');

    if (queueItem.priority > 0) {
      buffer.writeln('*** ƯU TIÊN ***');
    }

    if (queueItem.notes?.isNotEmpty == true) {
      buffer.writeln('Ghi chú: ${queueItem.notes}');
    }

    buffer.writeln();
    buffer.writeln('-' * 40);
    buffer.writeln('Vui lòng chờ được gọi');
    buffer.writeln('Cảm ơn quý khách!');
    buffer.writeln('-' * 40);
    buffer.writeln();
    buffer.writeln();

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  // Generate test ticket
  Uint8List _generateTestTicket(QueueItem testItem, DeviceConfig config) {
    final List<int> bytes = [];

    // ESC/POS Commands for thermal printer
    const esc = 0x1B;
    const gs = 0x1D;

    // Initialize printer
    bytes.addAll([esc, 0x40]); // ESC @ - Initialize

    // Center alignment
    bytes.addAll([esc, 0x61, 0x01]); // ESC a 1 - Center alignment

    // Title
    bytes.addAll([esc, 0x21, 0x30]); // ESC ! 48 - Double width and height
    bytes.addAll(utf8.encode('TEST PRINT'));
    bytes.addAll([0x0A, 0x0A]); // LF LF

    // Reset font
    bytes.addAll([esc, 0x21, 0x00]); // ESC ! 0 - Normal font

    // Store info
    bytes.addAll(utf8.encode(config.storeId));
    bytes.addAll([0x0A]); // LF
    bytes.addAll(utf8.encode(config.deviceName));
    bytes.addAll([0x0A, 0x0A]); // LF LF

    // Test number
    bytes.addAll([gs, 0x21, 0x22]); // GS ! 34 - 3x width, 3x height
    bytes.addAll(utf8.encode(testItem.displayNumber));
    bytes.addAll([0x0A, 0x0A]); // LF LF

    // Reset font
    bytes.addAll([gs, 0x21, 0x00]); // GS ! 0 - Normal size

    // Test info
    bytes.addAll([esc, 0x61, 0x00]); // ESC a 0 - Left alignment
    final dateTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    bytes.addAll(utf8.encode('Test Time: $dateTime'));
    bytes.addAll([0x0A]); // LF
    bytes.addAll(utf8.encode('Printer: ${config.printerConnectionString}'));
    bytes.addAll([0x0A]); // LF
    bytes.addAll(utf8.encode('Job: #${_printJobCounter}'));
    bytes.addAll([0x0A, 0x0A]); // LF LF

    // Status
    bytes.addAll([esc, 0x61, 0x01]); // ESC a 1 - Center alignment
    bytes.addAll(utf8.encode('PRINTER STATUS: OK'));
    bytes.addAll([0x0A]); // LF
    bytes.addAll(utf8.encode('✓ Connection successful'));
    bytes.addAll([0x0A]); // LF
    bytes.addAll(utf8.encode('✓ Print test passed'));
    bytes.addAll([0x0A, 0x0A, 0x0A]); // LF LF LF

    // Cut paper
    bytes.addAll([gs, 0x56, 0x00]); // GS V 0 - Full cut

    return Uint8List.fromList(bytes);
  }

  // Check printer status
  Future<bool> _checkPrinterStatus() async {
    try {
      // Send status request (ESC/POS)
      const esc = 0x1B;
      final statusRequest = [esc, 0x76]; // ESC v - Transmit paper sensor status

      _socket!.add(statusRequest);
      await _socket!.flush();

      // Wait for response (simplified - would need proper parsing in production)
      await Future.delayed(const Duration(milliseconds: 500));

      return true; // Assume OK if no exception
    } catch (e) {
      AppHelpers.logError('Printer status check failed', e);
      return false;
    }
  }

  // Socket event handlers
  void _onData(Uint8List data) {
    // Handle printer responses
    AppHelpers.logDebug('Printer response: ${data.length} bytes', tag: 'PRINTER');

    // Simple status parsing (would be more complex in production)
    if (data.isNotEmpty) {
      final status = data[0];
      if (status == 0x00) {
        _setStatus(PrinterStatus.ready);
      } else if (status == 0x0C) {
        _setStatus(PrinterStatus.outOfPaper);
      }
    }
  }

  void _onError(dynamic error) {
    _lastError = error.toString();
    _setStatus(PrinterStatus.error);
    AppHelpers.logError('Printer socket error', error);
  }

  void _onDisconnected() {
    _setStatus(PrinterStatus.disconnected);
    AppHelpers.logDebug('Printer socket disconnected', tag: 'PRINTER');
  }

  // Set status and notify listeners
  void _setStatus(PrinterStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
      AppHelpers.logDebug('Printer status: ${status.toString().split('.').last}', tag: 'PRINTER');
    }
  }

  // Test printer connection
  static Future<bool> testConnection(String ip, int port, {int timeoutSeconds = 5}) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(seconds: timeoutSeconds),
      );

      await socket.close();
      return true;
    } catch (e) {
      AppHelpers.logError('Printer test connection failed', e);
      return false;
    }
  }

  // Get printer info for debugging
  Map<String, dynamic> getPrinterInfo() {
    return {
      'status': _status.toString().split('.').last,
      'last_error': _lastError,
      'print_jobs': _printJobCounter,
      'ip': _config?.printerIP,
      'port': _config?.printerPort,
      'type': _config?.printerType,
      'is_connected': isConnected,
      'socket_address': _socket?.remoteAddress.address,
      'socket_port': _socket?.remotePort,
    };
  }

  // Cleanup resources
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// Printer utilities
class PrinterUtils {
  // ESC/POS command constants
  static const int ESC = 0x1B;
  static const int GS = 0x1D;
  static const int LF = 0x0A;
  static const int CR = 0x0D;

  // Text formatting commands
  static List<int> get initialize => [ESC, 0x40];
  static List<int> get centerAlign => [ESC, 0x61, 0x01];
  static List<int> get leftAlign => [ESC, 0x61, 0x00];
  static List<int> get rightAlign => [ESC, 0x61, 0x02];
  static List<int> get emphasizeOn => [ESC, 0x45, 0x01];
  static List<int> get emphasizeOff => [ESC, 0x45, 0x00];
  static List<int> get doubleSize => [ESC, 0x21, 0x30];
  static List<int> get normalSize => [ESC, 0x21, 0x00];
  static List<int> get cutPaper => [GS, 0x56, 0x00];

  // Convert text to printable bytes
  static List<int> textToBytes(String text) {
    return utf8.encode(text);
  }

  // Create line of characters
  static List<int> createLine(String char, int count) {
    return utf8.encode(char * count);
  }

  // Add line feed
  static List<int> get lineFeed => [LF];

  // Add multiple line feeds
  static List<int> multipleLineFeeds(int count) {
    return List.filled(count, LF);
  }
}