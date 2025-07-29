// lib/screens/setup/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../models/device_config.dart';
import '../../services/config_service.dart';
import '../../services/mqtt_service.dart';
import '../../services/printer_service.dart';
import '../../utils/constants.dart';
import '../../utils/validation_rules.dart';
import '../../widgets/status_indicator.dart';
import '../../widgets/action_button.dart';
import '../../widgets/config_summary_card.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final _storeIdController = TextEditingController();
  final _deviceNameController = TextEditingController(text: 'Máy in quầy 1');
  final _mqttBrokerController = TextEditingController();
  final _mqttPortController = TextEditingController(text: '1883');
  final _mqttUsernameController = TextEditingController();
  final _mqttPasswordController = TextEditingController();
  final _printerIPController = TextEditingController();
  final _printerPortController = TextEditingController(text: '9100');
  final _queuePrefixController = TextEditingController(text: 'A');
  final _startNumberController = TextEditingController(text: '1');
  final _resetTimeController = TextEditingController(text: '00:00');

  String _printerType = 'thermal';
  String _mqttStatus = 'CHƯA TEST';
  String _printerStatus = 'CHƯA TEST';
  String _configStatus = 'CHƯA LƯU';

  bool _isTestingMqtt = false;
  bool _isTestingPrinter = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // ✅ Bỏ setup animations và clock stream
    _loadExistingConfig();
    print("🔧 [SETUP] Setup screen initialized");
  }

  @override
  void dispose() {
    print("🧹 [SETUP] Disposing setup screen...");
    _pageController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    try {
      _storeIdController.dispose();
      _deviceNameController.dispose();
      _mqttBrokerController.dispose();
      _mqttPortController.dispose();
      _mqttUsernameController.dispose();
      _mqttPasswordController.dispose();
      _printerIPController.dispose();
      _printerPortController.dispose();
      _queuePrefixController.dispose();
      _startNumberController.dispose();
      _resetTimeController.dispose();
      print("✅ [SETUP] Controllers disposed");
    } catch (e) {
      print("⚠️ [SETUP] Error disposing controllers: $e");
    }
  }

  Future<void> _loadExistingConfig() async {
    try {
      final configService = context.read<ConfigService>();
      final config = configService.config;

      if (config != null) {
        setState(() {
          _storeIdController.text = config.storeId;
          _deviceNameController.text = config.deviceName;
          _mqttBrokerController.text = config.mqttBroker;
          _mqttPortController.text = config.mqttPort.toString();
          _mqttUsernameController.text = config.mqttUsername;
          _mqttPasswordController.text = config.mqttPassword;
          _printerIPController.text = config.printerIP;
          _printerPortController.text = config.printerPort.toString();
          _queuePrefixController.text = config.queuePrefix;
          _startNumberController.text = config.startNumber.toString();
          _resetTimeController.text = config.resetTime;
          _printerType = config.printerType;
          _configStatus = 'ĐÃ LƯU';
        });
        print("✅ [SETUP] Existing config loaded");
      }
    } catch (e) {
      print("⚠️ [SETUP] Error loading existing config: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('CẤU HÌNH MÁY IN PHIẾU'),
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousPage,
        )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              children: [
                _buildBasicConfigPage(),
                _buildConnectionConfigPage(),
                _buildTestSavePage(),
              ],
            ),
          ),

          // Bottom navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Color(AppConstants.colors['primary']!),
      child: Row(
        children: [
          _buildProgressStep(0, 'Cơ bản', Icons.info),
          _buildProgressStep(1, 'Kết nối', Icons.wifi),
          _buildProgressStep(2, 'Hoàn tất', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, IconData icon) {
    final isActive = step <= _currentPage;
    final isCompleted = step < _currentPage;

    return Expanded(
      child: Row(
        children: [
          // Step indicator
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green
                  : isActive
                  ? Colors.white
                  : Colors.blue[400],
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted
                  ? Colors.white
                  : isActive
                  ? Color(AppConstants.colors['primary']!)
                  : Colors.white,
              size: 20.w,
            ),
          ),

          if (step < 2) ...[
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (step < 1)
              Container(
                height: 2.h,
                color: step < _currentPage ? Colors.green : Colors.white30,
                width: 20.w,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicConfigPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              'THÔNG TIN CƠ BẢN',
              Icons.info,
              [
                TextFormField(
                  controller: _storeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Store ID *',
                    hintText: 'STORE001, BRANCH_HCM, etc.',
                    prefixIcon: Icon(Icons.store),
                    helperText: 'ID duy nhất của cửa hàng/chi nhánh',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return ErrorMessages.emptyStoreId;
                    }
                    if (!ValidationRules.isValidStoreId(value!)) {
                      return ErrorMessages.invalidStoreId;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                TextFormField(
                  controller: _deviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên thiết bị',
                    hintText: 'Máy in quầy 1',
                    prefixIcon: Icon(Icons.tablet_android),
                    helperText: 'Tên hiển thị của thiết bị này',
                  ),
                  validator: (value) {
                    if (value != null &&
                        value.length > ValidationRules.maxDeviceNameLength) {
                      return 'Tên thiết bị không được quá ${ValidationRules.maxDeviceNameLength} ký tự';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),

                // Queue settings
                Text(
                  'CẤU HÌNH HÀNG ĐỢI',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _queuePrefixController,
                        decoration: const InputDecoration(
                          labelText: 'Prefix số',
                          hintText: 'A, B, VIP',
                          helperText: 'Chữ cái đầu số',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value?.isEmpty == true) {
                            return ErrorMessages.emptyPrefix;
                          }
                          if (!ValidationRules.isValidPrefix(value!)) {
                            return ErrorMessages.invalidPrefix;
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: TextFormField(
                        controller: _startNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Số bắt đầu',
                          hintText: '1',
                          helperText: 'Số đầu tiên',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final number = int.tryParse(value ?? '');
                          if (number == null || number < 1) {
                            return 'Số bắt đầu phải lớn hơn 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: TextFormField(
                        controller: _resetTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Reset lúc',
                          hintText: '00:00',
                          helperText: 'Giờ reset hàng ngày',
                        ),
                        validator: (value) {
                          if (value?.isNotEmpty == true &&
                              !ValidationRules.isValidTime(value!)) {
                            return ErrorMessages.invalidResetTime;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 24.h),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionConfigPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildSectionCard(
            'MQTT BROKER',
            Icons.wifi,
            [
              TextFormField(
                controller: _mqttBrokerController,
                decoration: const InputDecoration(
                  labelText: 'MQTT Broker IP/Domain *',
                  hintText: '192.168.1.100 hoặc mqtt.example.com',
                  prefixIcon: Icon(Icons.dns),
                  helperText: 'Địa chỉ máy chủ MQTT',
                ),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return ErrorMessages.emptyMqttBroker;
                  }
                  final isValidIP = ValidationRules.isValidIP(value!);
                  final isValidDomain = ValidationRules.isValidDomain(value);
                  if (!isValidIP && !isValidDomain) {
                    return ErrorMessages.invalidMqttBroker;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _mqttPortController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '1883',
                        helperText: 'Cổng kết nối',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final port = int.tryParse(value ?? '');
                        if (port == null || !ValidationRules.isValidPort(port)) {
                          return ErrorMessages.invalidMqttPort;
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _mqttUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username (tùy chọn)',
                        helperText: 'Tên đăng nhập',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _mqttPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Password (tùy chọn)',
                  prefixIcon: Icon(Icons.lock),
                  helperText: 'Mật khẩu đăng nhập',
                ),
                obscureText: true,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          _buildSectionCard(
            'MÁY IN',
            Icons.print,
            [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Loại máy in',
                  prefixIcon: Icon(Icons.print),
                  helperText: 'Chọn loại máy in',
                ),
                value: _printerType,
                items: const [
                  DropdownMenuItem(
                      value: 'thermal', child: Text('Thermal (80mm)')),
                  DropdownMenuItem(
                      value: 'laser', child: Text('Laser/Inkjet')),
                  DropdownMenuItem(value: 'pos', child: Text('POS Printer')),
                ],
                onChanged: (value) => setState(() => _printerType = value!),
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _printerIPController,
                      decoration: const InputDecoration(
                        labelText: 'IP Máy in *',
                        hintText: '192.168.1.50',
                        helperText: 'Địa chỉ IP máy in',
                      ),
                      validator: (value) {
                        if (value?.isEmpty == true) {
                          return ErrorMessages.emptyPrinterIP;
                        }
                        if (!ValidationRules.isValidIP(value!)) {
                          return ErrorMessages.invalidPrinterIP;
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: TextFormField(
                      controller: _printerPortController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '9100',
                        helperText: 'Cổng máy in',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final port = int.tryParse(value ?? '');
                        if (port == null || !ValidationRules.isValidPort(port)) {
                          return ErrorMessages.invalidPrinterPort;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestSavePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildSectionCard(
            'TEST KẾT NỐI',
            Icons.wifi_find,
            [
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'TEST MQTT',
                      icon: Icons.wifi,
                      backgroundColor: Colors.orange,
                      isLoading: _isTestingMqtt,
                      onPressed: _testMqttConnection,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ActionButton(
                      text: 'TEST PRINTER',
                      icon: Icons.print,
                      backgroundColor: Colors.orange,
                      isLoading: _isTestingPrinter,
                      onPressed: _testPrinterConnection,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16.h),
          _buildStatusCard(),
          SizedBox(height: 16.h),
          _buildConfigSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(AppConstants.colors['primary']!)),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.colors['primary']!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Color(AppConstants.colors['primary']!)),
              SizedBox(width: 8.w),
              Text(
                'HƯỚNG DẪN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.colors['primary']!),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          const Text('• Store ID phải giống với Tablet 2 và TV Display'),
          const Text('• Prefix số sẽ hiển thị trước số thứ tự (A001, B001, ...)'),
          const Text(
              '• Reset time là giờ reset số về 1 hàng ngày (mặc định 00:00)'),
          const Text('• Tất cả thiết bị phải cùng mạng WiFi'),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRẠNG THÁI HỆ THỐNG',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            StatusIndicator(
                label: 'MQTT Broker', status: _mqttStatus, icon: Icons.wifi),
            StatusIndicator(
                label: 'Máy in', status: _printerStatus, icon: Icons.print),
            StatusIndicator(
                label: 'Cấu hình', status: _configStatus, icon: Icons.settings),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSummaryCard() {
    return ConfigSummaryCard(
      title: 'TÓM TẮT CẤU HÌNH',
      items: {
        'Store ID:': _storeIdController.text,
        'Device:': _deviceNameController.text,
        'MQTT:':
        '${_mqttBrokerController.text}:${_mqttPortController.text}',
        'Printer:':
        '${_printerIPController.text}:${_printerPortController.text}',
        'Queue:':
        '${_queuePrefixController.text} từ số ${_startNumberController.text}',
        'Reset:': _resetTimeController.text.isEmpty
            ? 'Không reset'
            : _resetTimeController.text,
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: ActionButton(
                text: 'QUAY LẠI',
                icon: Icons.arrow_back,
                backgroundColor: Colors.grey[600],
                onPressed: _previousPage,
              ),
            ),
          if (_currentPage > 0) SizedBox(width: 16.w),
          Expanded(
            child: ActionButton(
              text: _currentPage < 2 ? 'TIẾP THEO' : 'LƯU VÀ KHỞI ĐỘNG',
              icon: _currentPage < 2 ? Icons.arrow_forward : Icons.save,
              isLoading: _isSaving,
              onPressed: _currentPage < 2 ? _nextPage : _saveAndContinue,
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    // ✅ Safe null check
    if (_currentPage == 0) {
      if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
        return;
      }
    }

    _pageController.nextPage(
      duration: AppConstants.animationDuration,
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: AppConstants.animationDuration,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _testMqttConnection() async {
    print("🔵 [MQTT TEST] Starting test...");
    setState(() => _isTestingMqtt = true);

    try {
      // ✅ Lấy data trực tiếp từ form controllers
      final broker = _mqttBrokerController.text.trim();
      final portText = _mqttPortController.text.trim();
      final username = _mqttUsernameController.text.trim();
      final password = _mqttPasswordController.text.trim();

      print("🔵 [MQTT TEST] Data from form:");
      print("   Broker: '$broker'");
      print("   Port: '$portText'");
      print("   Username: '${username.isEmpty ? 'empty' : username}'");

      // Validate trước khi test
      if (broker.isEmpty) {
        throw Exception('MQTT Broker không được để trống');
      }

      final port = int.tryParse(portText);
      if (port == null || port < 1 || port > 65535) {
        throw Exception('Port MQTT không hợp lệ: $portText');
      }

      // ✅ Test với data từ form (KHÔNG dùng ConfigService)
      print("🔵 [MQTT TEST] Testing connection...");
      final testResult = await MqttService.testConnection(
        broker: broker,
        port: port,
        username: username.isEmpty ? null : username,
        password: password.isEmpty ? null : password,
        timeoutSeconds: 10,
      );

      print("🔵 [MQTT TEST] Result: $testResult");

      setState(() {
        _mqttStatus = testResult ? 'OK' : 'ERROR';
        _isTestingMqtt = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  testResult ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(testResult
                    ? '✅ MQTT kết nối thành công!'
                    : '❌ MQTT kết nối thất bại'),
              ],
            ),
            backgroundColor: testResult ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print("❌ [MQTT TEST ERROR] $e");
      print("📍 [MQTT TEST STACK] $stackTrace");

      setState(() {
        _mqttStatus = 'ERROR';
        _isTestingMqtt = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi MQTT: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _testPrinterConnection() async {
    print("🟢 [PRINTER TEST] Starting test...");
    setState(() => _isTestingPrinter = true);

    try {
      // ✅ Lấy data trực tiếp từ form controllers
      final printerIP = _printerIPController.text.trim();
      final portText = _printerPortController.text.trim();

      print("🟢 [PRINTER TEST] Data from form:");
      print("   IP: '$printerIP'");
      print("   Port: '$portText'");

      // Validate trước khi test
      if (printerIP.isEmpty) {
        throw Exception('IP máy in không được để trống');
      }

      // Validate IP format
      if (!_isValidIPAddress(printerIP)) {
        throw Exception('Địa chỉ IP không hợp lệ: $printerIP');
      }

      final port = int.tryParse(portText);
      if (port == null || port < 1 || port > 65535) {
        throw Exception('Port máy in không hợp lệ: $portText');
      }

      // ✅ Test với data từ form (KHÔNG dùng ConfigService)
      print("🟢 [PRINTER TEST] Testing connection...");
      final testResult = await PrinterService.testConnection(
        printerIP,
        port,
        timeoutSeconds: 5,
      );

      print("🟢 [PRINTER TEST] Result: $testResult");

      setState(() {
        _printerStatus = testResult ? 'OK' : 'ERROR';
        _isTestingPrinter = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  testResult ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(testResult
                    ? '✅ Máy in kết nối thành công!'
                    : '❌ Máy in kết nối thất bại'),
              ],
            ),
            backgroundColor: testResult ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print("❌ [PRINTER TEST ERROR] $e");
      print("📍 [PRINTER TEST STACK] $stackTrace");

      setState(() {
        _printerStatus = 'ERROR';
        _isTestingPrinter = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi máy in: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Helper method để validate IP
  bool _isValidIPAddress(String ip) {
    print("🔍 [VALIDATION] Checking IP: $ip");

    if (ip.isEmpty) return false;

    final parts = ip.split('.');
    if (parts.length != 4) {
      print("❌ [VALIDATION] IP must have 4 parts, got ${parts.length}");
      return false;
    }

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final num = int.tryParse(part);

      if (num == null) {
        print("❌ [VALIDATION] Part $i '$part' is not a number");
        return false;
      }

      if (num < 0 || num > 255) {
        print("❌ [VALIDATION] Part $i '$part' out of range (0-255)");
        return false;
      }
    }

    print("✅ [VALIDATION] IP format OK");
    return true;
  }

  Future<void> _saveAndContinue() async {
    print("💾 [SETUP] Starting save configuration...");

    // ✅ Check null trước khi dùng !
    if (_formKey.currentState == null) {
      print("❌ [SETUP] Form key is null");
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print("❌ [SETUP] Form validation failed");
      return;
    }

    // ✅ Check mounted trước khi setState
    if (!mounted) {
      print("❌ [SETUP] Widget not mounted");
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ✅ Save form data trước
      _formKey.currentState!.save();

      print("📝 [SETUP] Creating config object...");

      // ✅ Parse port với error handling
      int mqttPort;
      int printerPort;
      int startNumber;

      try {
        mqttPort = int.parse(_mqttPortController.text.trim());
      } catch (e) {
        throw Exception('MQTT Port không hợp lệ: ${_mqttPortController.text}');
      }

      try {
        printerPort = int.parse(_printerPortController.text.trim());
      } catch (e) {
        throw Exception('Printer Port không hợp lệ: ${_printerPortController.text}');
      }

      try {
        startNumber = int.parse(_startNumberController.text.trim());
      } catch (e) {
        throw Exception('Số bắt đầu không hợp lệ: ${_startNumberController.text}');
      }

      final config = DeviceConfig(
        deviceType: AppConstants.deviceType,
        storeId: _storeIdController.text.trim().toUpperCase(),
        deviceName: _deviceNameController.text.trim(),
        mqttBroker: _mqttBrokerController.text.trim(),
        mqttPort: mqttPort,
        mqttUsername: _mqttUsernameController.text.trim(),
        mqttPassword: _mqttPasswordController.text.trim(),
        printerIP: _printerIPController.text.trim(),
        printerPort: printerPort,
        printerType: _printerType,
        queuePrefix: _queuePrefixController.text.trim().toUpperCase(),
        startNumber: startNumber,
        resetTime: _resetTimeController.text.trim(),
      );

      print("✅ [SETUP] Config created: ${config.storeId}");
      print("🔍 [SETUP] Config valid: ${config.isValid}");

      if (!config.isValid) {
        final errors = config.validationErrors;
        print("❌ [SETUP] Config validation errors: $errors");
        throw Exception("Cấu hình không hợp lệ:\n${errors.join('\n')}");
      }

      // ✅ Check context và mounted trước khi dùng
      if (!mounted) {
        print("❌ [SETUP] Widget unmounted before save");
        return;
      }

      print("💾 [SETUP] Saving to ConfigService...");

      // ✅ Safe way to get ConfigService
      ConfigService? configService;
      try {
        configService = context.read<ConfigService>();
      } catch (e) {
        print("❌ [SETUP] Cannot get ConfigService: $e");
        throw Exception('Không thể truy cập ConfigService');
      }

      if (configService == null) {
        throw Exception('ConfigService is null');
      }

      final saved = await configService.saveConfig(config);
      print("✅ [SETUP] Save result: $saved");

      if (!mounted) {
        print("❌ [SETUP] Widget unmounted after save");
        return;
      }

      if (saved) {
        setState(() {
          _configStatus = 'ĐÃ LƯU';
          _isSaving = false;
        });

        print("🧭 [SETUP] Showing success message...");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cấu hình đã được lưu thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Đợi một chút để user thấy success message
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          print("🧭 [SETUP] Navigating to main screen...");
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else {
        throw Exception('Lưu cấu hình thất bại');
      }
    } catch (e, stackTrace) {
      print("❌ [SETUP ERROR] $e");
      print("📍 [SETUP STACK] $stackTrace");

      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❌ Lỗi lưu cấu hình:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(e.toString()),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'ĐÓNG',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trợ giúp cấu hình'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏪 Store ID: Mã định danh duy nhất cho cửa hàng'),
            SizedBox(height: 8),
            Text('📱 Device Name: Tên hiển thị của thiết bị này'),
            SizedBox(height: 8),
            Text('🌐 MQTT Broker: Máy chủ trung gian để liên lạc giữa các thiết bị'),
            SizedBox(height: 8),
            Text('🖨️ Printer IP: Địa chỉ mạng của máy in'),
            SizedBox(height: 8),
            Text('🔤 Queue Prefix: Chữ cái đầu của số thứ tự (A001, B001...)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}