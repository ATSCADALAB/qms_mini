// lib/screens/setup/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../models/device_config.dart';
import '../../services/config_service.dart';
import '../../services/mqtt_service.dart';
import '../../services/printer_service.dart';
import '../../utils/constants.dart';
import '../../utils/validation_rules.dart'; // Giả sử bạn có file này, nếu không hãy xóa hoặc thay bằng logic tương ứng
import '../../widgets/status_indicator.dart';
import '../../widgets/action_button.dart';
import '../../widgets/config_summary_card.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // GlobalKey cho Form cha duy nhất
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
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
    print("🔧 [SETUP] Setup screen initialized");
  }

  @override
  void dispose() {
    print("🧹 [SETUP] Starting dispose...");
    _isDisposed = true;

    try {
      _pageController.dispose();
      _disposeControllers();
    } catch (e) {
      print("⚠️ [SETUP] Error during dispose: $e");
    }

    super.dispose();
    print("✅ [SETUP] Dispose completed");
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

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  bool get _canUseContext => !_isDisposed && mounted && context.mounted;

  Future<void> _loadExistingConfig() async {
    try {
      // Chờ frame đầu tiên build xong để context sẵn sàng
      await WidgetsBinding.instance.endOfFrame;
      if (!_canUseContext) return;

      final configService = context.read<ConfigService>();
      final config = configService.config;

      if (config != null) {
        _safeSetState(() {
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
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

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
      // SỬA LỖI: Bọc toàn bộ body bằng một Form widget duy nhất
      body: Form(
        key: _formKey, // Gán key cho Form cha này
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => _safeSetState(() => _currentPage = index),
                physics: const NeverScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      color: Color(AppConstants.colors['primary']!),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgressStep(0, 'Cơ bản', Icons.info_outline),
          _buildProgressLine(0),
          _buildProgressStep(1, 'Kết nối', Icons.wifi),
          _buildProgressLine(1),
          _buildProgressStep(2, 'Hoàn tất', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, IconData icon) {
    final isActive = step <= _currentPage;
    final isCompleted = step < _currentPage;

    return Column(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : (isActive ? Colors.white : Colors.blue[400]),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isActive && !isCompleted ? Color(AppConstants.colors['primary']!) : Colors.white,
            size: 18.w,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        )
      ],
    );
  }

  Widget _buildProgressLine(int step) {
    final isCompleted = step < _currentPage;
    return Expanded(
      child: Container(
        height: 2.h,
        color: isCompleted ? Colors.green : Colors.white30,
        margin: EdgeInsets.only(bottom: 20.h),
      ),
    );
  }

  Widget _buildBasicConfigPage() {
    // SỬA LỖI: Không cần Widget Form ở đây nữa
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
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
                  if (value?.isEmpty ?? true) {
                    return 'Store ID không được để trống';
                  }
                  if (value!.length < 3) {
                    return 'Store ID phải có ít nhất 3 ký tự';
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
                  if (value != null && value.length > 50) {
                    return 'Tên thiết bị không được quá 50 ký tự';
                  }
                  return null;
                },
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSectionCard(
            'CẤU HÌNH HÀNG ĐỢI',
            Icons.format_list_numbered,
            [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _queuePrefixController,
                      decoration: const InputDecoration(
                        labelText: 'Prefix số',
                        hintText: 'A, B, VIP',
                        helperText: 'Chữ cái đầu',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Prefix không được để trống';
                        }
                        if (value!.length > 5) {
                          return 'Prefix không được quá 5 ký tự';
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
                          return 'Phải > 0';
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
                        helperText: 'Giờ reset',
                      ),
                      validator: (value) {
                        if (value?.isNotEmpty == true) {
                          final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
                          if (!timeRegex.hasMatch(value!)) {
                            return 'Sai (HH:mm)';
                          }
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
    );
  }

  Widget _buildConnectionConfigPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildSectionCard(
            'MQTT BROKER',
            Icons.cloud_queue,
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
                  if (value?.isEmpty ?? true) {
                    return 'MQTT Broker không được để trống';
                  }
                  return null; // Thêm validation chi tiết nếu cần
                },
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _mqttPortController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '1883',
                        helperText: 'Cổng',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final port = int.tryParse(value ?? '');
                        if (port == null || port < 1 || port > 65535) {
                          return 'Port sai';
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
                  prefixIcon: Icon(Icons.lock_outline),
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
                  //prefixIcon: Icon(Icons.print_outline),
                  helperText: 'Chọn loại máy in phù hợp',
                ),
                value: _printerType,
                items: const [
                  DropdownMenuItem(value: 'thermal', child: Text('Thermal (ESC/POS)')),
                  // DropdownMenuItem(value: 'laser', child: Text('Laser/Inkjet')),
                  // DropdownMenuItem(value: 'pos', child: Text('POS Printer')),
                ],
                onChanged: (value) => _safeSetState(() => _printerType = value!),
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _printerIPController,
                      decoration: const InputDecoration(
                        labelText: 'IP Máy in *',
                        hintText: '192.168.1.50',
                        helperText: 'Địa chỉ IP của máy in',
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'IP không được trống';
                        }
                        // Sử dụng helper function để validate IP
                        if (!_isValidIPAddress(value!)) {
                          return 'Địa chỉ IP không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _printerPortController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '9100',
                        helperText: 'Cổng',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final port = int.tryParse(value ?? '');
                        if (port == null || port < 1 || port > 65535) {
                          return 'Port sai';
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
            'KIỂM TRA & XÁC NHẬN',
            Icons.wifi_find,
            [
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'TEST MQTT',
                      icon: Icons.cloud_sync_outlined,
                      backgroundColor: Colors.orange,
                      isLoading: _isTestingMqtt,
                      onPressed: _testMqttConnection,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ActionButton(
                      text: 'TEST MÁY IN',
                      icon: Icons.print_outlined,
                      backgroundColor: Colors.blue,
                      isLoading: _isTestingPrinter,
                      onPressed: _testPrinterConnection,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildStatusCard(),
            ],
          ),
          SizedBox(height: 16.h),
          _buildConfigSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(AppConstants.colors['primary']!), size: 24.w),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.colors['primary']!),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'LƯU Ý QUAN TRỌNG',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('• Store ID phải giống hệt nhau trên tất cả các thiết bị.'),
          SizedBox(height: 4),
          Text('• Prefix số sẽ hiển thị trước số thứ tự (ví dụ: A001).'),
          SizedBox(height: 4),
          Text('• Tất cả thiết bị phải kết nối vào cùng một mạng WiFi/LAN.'),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusIndicator(label: 'MQTT Broker', status: _mqttStatus, icon: Icons.cloud_queue),
          SizedBox(height: 8.h),
          StatusIndicator(label: 'Máy in', status: _printerStatus, icon: Icons.print),
          SizedBox(height: 8.h),
          StatusIndicator(label: 'Cấu hình', status: _configStatus, icon: Icons.settings_applications),
        ],
      ),
    );
  }

  Widget _buildConfigSummaryCard() {
    return ConfigSummaryCard(
      title: 'TÓM TẮT CẤU HÌNH',
      items: {
        'Store ID:': _storeIdController.text,
        'Tên thiết bị:': _deviceNameController.text,
        'MQTT:': '${_mqttBrokerController.text}:${_mqttPortController.text}',
        'Máy in:': '${_printerIPController.text}:${_printerPortController.text}',
        'Hàng đợi:': '${_queuePrefixController.text} (bắt đầu từ ${_startNumberController.text})',
        'Reset lúc:': _resetTimeController.text.isEmpty ? 'Không reset' : _resetTimeController.text,
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
              text: _currentPage < 2 ? 'TIẾP THEO' : 'LƯU & KHỞI ĐỘNG',
              icon: _currentPage < 2 ? Icons.arrow_forward : Icons.save,
              isLoading: _isSaving,
              onPressed: _currentPage < 2 ? _nextPage : _saveAndContinue,
            ),
          ),
        ],
      ),
    );
  }

  // LOGIC METHODS

  void _nextPage() {
    if (!_canUseContext || _isSaving) return;

    // Validate toàn bộ form trước khi chuyển trang
    // Điều này sẽ kiểm tra các trường đã hiển thị
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      _performPageNavigation(true);
    } else {
      print("❌ [SETUP] Form validation failed on page $_currentPage");
      _showSnackBar('Vui lòng điền đúng và đủ thông tin bắt buộc (*)', Colors.red);
    }
  }

  void _previousPage() {
    if (!_canUseContext || _isSaving) return;
    _performPageNavigation(false);
  }

  void _performPageNavigation(bool isNext) {
    if (!_canUseContext) return;
    final duration = AppConstants.animationDuration;
    final curve = Curves.easeInOut;

    if (isNext) {
      _pageController.nextPage(duration: duration, curve: curve);
    } else {
      _pageController.previousPage(duration: duration, curve: curve);
    }
  }

  Future<void> _testMqttConnection() async {
    if (!_canUseContext || _isTestingMqtt) return;
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    print("🔵 [MQTT TEST] Starting test...");
    _safeSetState(() {
      _isTestingMqtt = true;
      _mqttStatus = 'ĐANG TEST...';
    });

    try {
      final broker = _mqttBrokerController.text.trim();
      final portText = _mqttPortController.text.trim();
      final username = _mqttUsernameController.text.trim();
      final password = _mqttPasswordController.text.trim();

      if (broker.isEmpty || portText.isEmpty) {
        throw Exception('Chưa nhập IP/Port của MQTT Broker');
      }

      final port = _parsePort(portText, 'MQTT Port');

      final testResult = await MqttService.testConnection(
        broker: broker,
        port: port,
        username: username.isEmpty ? null : username,
        password: password.isEmpty ? null : password,
        timeoutSeconds: 5,
      );

      if (!_canUseContext) return;

      _safeSetState(() {
        _mqttStatus = testResult ? 'OK' : 'LỖI';
      });

      _showSnackBar(
        testResult ? '✅ MQTT kết nối thành công!' : '❌ MQTT kết nối thất bại!',
        testResult ? Colors.green : Colors.red,
      );

    } catch (e) {
      print("❌ [MQTT TEST ERROR] $e");
      if (_canUseContext) {
        _safeSetState(() => _mqttStatus = 'LỖI');
        _showSnackBar('❌ Lỗi MQTT: ${e.toString().replaceFirst("Exception: ", "")}', Colors.red);
      }
    } finally {
      if (_canUseContext) {
        _safeSetState(() => _isTestingMqtt = false);
      }
    }
  }

  Future<void> _testPrinterConnection() async {
    if (!_canUseContext || _isTestingPrinter) return;
    FocusScope.of(context).unfocus();

    print("🟢 [PRINTER TEST] Starting test...");
    _safeSetState(() {
      _isTestingPrinter = true;
      _printerStatus = 'ĐANG TEST...';
    });

    try {
      final printerIP = _printerIPController.text.trim();
      final portText = _printerPortController.text.trim();

      if (printerIP.isEmpty || portText.isEmpty) {
        throw Exception('Chưa nhập IP/Port của máy in');
      }
      if (!_isValidIPAddress(printerIP)) {
        throw Exception('Địa chỉ IP không hợp lệ');
      }

      final port = _parsePort(portText, 'Printer Port');

      final testResult = await PrinterService.testConnection(
        printerIP,
        port,
        timeoutSeconds: 5,
      );

      if (!_canUseContext) return;

      _safeSetState(() {
        _printerStatus = testResult ? 'OK' : 'LỖI';
      });

      _showSnackBar(
        testResult ? '✅ Máy in kết nối thành công!' : '❌ Máy in kết nối thất bại!',
        testResult ? Colors.green : Colors.red,
      );

    } catch (e) {
      print("❌ [PRINTER TEST ERROR] $e");
      if (_canUseContext) {
        _safeSetState(() => _printerStatus = 'LỖI');
        _showSnackBar('❌ Lỗi máy in: ${e.toString().replaceFirst("Exception: ", "")}', Colors.red);
      }
    } finally {
      if (_canUseContext) {
        _safeSetState(() => _isTestingPrinter = false);
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving || !_canUseContext) {
      print("⚠️ [SETUP] Save already in progress or widget disposed");
      return;
    }

    // Ẩn bàn phím trước khi validate
    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;
    if (formState == null) {
      print("❌ [SETUP] Form state is null, cannot proceed.");
      _showSnackBar('Form chưa sẵn sàng, vui lòng thử lại', Colors.red);
      return;
    }

    if (!formState.validate()) {
      print("❌ [SETUP] Form validation failed");
      _showSnackBar('Vui lòng điền đúng và đủ thông tin bắt buộc (*)', Colors.red);
      return;
    }

    print("💾 [SETUP] Starting save configuration...");
    _safeSetState(() => _isSaving = true);

    try {
      formState.save();
      print("📝 [SETUP] Form data saved");

      final config = DeviceConfig(
        deviceType: AppConstants.deviceType,
        storeId: _storeIdController.text.trim().toUpperCase(),
        deviceName: _deviceNameController.text.trim(),
        mqttBroker: _mqttBrokerController.text.trim(),
        mqttPort: _parsePort(_mqttPortController.text.trim(), 'MQTT Port'),
        mqttUsername: _mqttUsernameController.text.trim(),
        mqttPassword: _mqttPasswordController.text.trim(),
        printerIP: _printerIPController.text.trim(),
        printerPort: _parsePort(_printerPortController.text.trim(), 'Printer Port'),
        printerType: _printerType,
        queuePrefix: _queuePrefixController.text.trim().toUpperCase(),
        startNumber: _parseStartNumber(_startNumberController.text.trim()),
        resetTime: _resetTimeController.text.trim(),
      );

      print("✅ [SETUP] Config created: ${config.storeId}");

      if (!config.isValid) {
        throw Exception("Cấu hình không hợp lệ:\n${config.validationErrors.join('\n')}");
      }

      final configService = context.read<ConfigService>();
      final saved = await configService.saveConfig(config);

      if (!_canUseContext) {
        print("❌ [SETUP] Widget disposed after save");
        return;
      }

      if (saved) {
        _safeSetState(() => _configStatus = 'ĐÃ LƯU');
        _showSnackBar('✅ Cấu hình đã được lưu thành công!', Colors.green);
        await Future.delayed(const Duration(seconds: 1));

        if (_canUseContext) {
          print("🧭 [SETUP] Navigating to main screen...");
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else {
        throw Exception('Lưu cấu hình thất bại.');
      }

    } catch (e, stackTrace) {
      print("❌ [SETUP ERROR] $e");
      print("📍 [SETUP STACK] $stackTrace");
      if (_canUseContext) {
        _showSnackBar('❌ Lỗi: ${e.toString().replaceFirst("Exception: ", "")}', Colors.red);
      }
    } finally {
      if (_canUseContext) {
        _safeSetState(() => _isSaving = false);
      }
    }
  }

  // HELPER METHODS

  int _parsePort(String value, String fieldName) {
    final port = int.tryParse(value);
    if (port == null || port < 1 || port > 65535) {
      throw Exception('$fieldName không hợp lệ: $value');
    }
    return port;
  }

  int _parseStartNumber(String value) {
    final number = int.tryParse(value);
    if (number == null || number < 1) {
      throw Exception('Số bắt đầu không hợp lệ: $value');
    }
    return number;
  }

  bool _isValidIPAddress(String ip) {
    // Regex đơn giản để check định dạng IP. Có thể dùng thư viện nếu cần check kỹ hơn.
    final ipRegex = RegExp(
        r"^(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)$");
    return ipRegex.hasMatch(ip);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!_canUseContext) return;

    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print("❌ [SETUP] Error showing snackbar: $e");
    }
  }

  void _showHelpDialog() {
    if (!_canUseContext) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trợ giúp cấu hình'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏪 Store ID:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Mã định danh duy nhất cho cửa hàng, phải giống nhau trên tất cả thiết bị.'),
              SizedBox(height: 8),
              Text('🌐 MQTT Broker:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Máy chủ trung gian để liên lạc giữa các thiết bị.'),
              SizedBox(height: 8),
              Text('🖨️ Printer IP:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Địa chỉ mạng của máy in trong mạng nội bộ.'),
              SizedBox(height: 8),
              Text('🔤 Queue Prefix:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Chữ cái đứng đầu của số thứ tự (A001, B001...).'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}