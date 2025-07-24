// lib/screens/main/print_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/config_service.dart';
import '../../services/database_service.dart';
import '../../models/queue_item.dart';
import '../../utils/constants.dart';
import '../../widgets/status_indicator.dart';
import '../../widgets/action_button.dart';
import '../../widgets/config_summary_card.dart';
import '../setup/setup_screen.dart';

class PrintScreen extends StatefulWidget {
  const PrintScreen({Key? key}) : super(key: key);

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();

  List<QueueItem> _todayQueue = [];
  Map<String, dynamic> _todayStats = {};
  bool _isLoading = false;
  bool _isPrinting = false;
  String _connectionStatus = 'CONNECTING...';

  late AnimationController _printButtonController;
  late AnimationController _refreshController;
  late Animation<double> _printButtonAnimation;

  // Auto-refresh timer
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupClockStream();
    _initializeScreen();
  }

  void _setupAnimations() {
    _printButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _printButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _printButtonController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupClockStream() {
    _clockStream = Stream.periodic(
      const Duration(seconds: 1),
          (_) => DateTime.now(),
    );
  }

  Future<void> _initializeScreen() async {
    await _loadTodayData();
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    // Refresh data every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadTodayData();
        _startPeriodicUpdates();
      }
    });
  }

  Future<void> _loadTodayData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final queue = await _databaseService.getTodayQueue();
      final stats = await _databaseService.getTodayStats();

      setState(() {
        _todayQueue = queue;
        _todayStats = stats;
        _connectionStatus = 'CONNECTED';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'ERROR';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _printButtonController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configService = context.watch<ConfigService>();
    final config = configService.config;

    if (config == null || !config.isValid) {
      return _buildConfigurationNeeded();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(config),
      body: Column(
        children: [
          // Status bar
          _buildStatusBar(config),

          // Main content
          Expanded(
            child: Row(
              children: [
                // Left panel - Print controls
                Expanded(
                  flex: 2,
                  child: _buildPrintPanel(config),
                ),

                // Right panel - Today's queue
                Expanded(
                  flex: 3,
                  child: _buildQueuePanel(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  PreferredSizeWidget _buildAppBar(config) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.print, size: 24.w),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MÁY IN PHIẾU',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              Text(
                config.deviceName,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w300),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Clock display
        StreamBuilder<DateTime>(
          stream: _clockStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat('HH:mm:ss').format(snapshot.data!),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        // Refresh button
        IconButton(
          icon: RotationTransition(
            turns: _refreshController,
            child: const Icon(Icons.refresh),
          ),
          onPressed: () {
            _refreshController.forward().then((_) {
              _refreshController.reset();
            });
            _loadTodayData();
          },
        ),

        // Settings menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Cài đặt'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Thông tin thiết bị'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'reconfigure',
              child: Row(
                children: [
                  Icon(Icons.build, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Cấu hình lại'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBar(config) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Color(AppConstants.colors['primary']!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Store info
          Expanded(
            child: Row(
              children: [
                Icon(Icons.store, color: Colors.white, size: 20.w),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.storeId,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      'Store ID',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Date info
          Expanded(
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white, size: 20.w),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE', 'vi').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Connection status
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: _getConnectionColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getConnectionColor().withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getConnectionText(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      'Trạng thái',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintPanel(config) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Main print button
          Expanded(
            flex: 3,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(AppConstants.colors['success']!),
                      Color(AppConstants.colors['success']!).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isPrinting ? null : _printTicket,
                    onTapDown: (_) => _printButtonController.forward(),
                    onTapUp: (_) => _printButtonController.reverse(),
                    onTapCancel: () => _printButtonController.reverse(),
                    child: ScaleTransition(
                      scale: _printButtonAnimation,
                      child: Container(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isPrinting) ...[
                              SizedBox(
                                width: 60.w,
                                height: 60.h,
                                child: const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 4,
                                ),
                              ),
                            ] else ...[
                              Icon(
                                Icons.print,
                                size: 80.w,
                                color: Colors.white,
                              ),
                            ],

                            SizedBox(height: 20.h),

                            Text(
                              _isPrinting ? 'ĐANG IN...' : 'IN PHIẾU SỐ THỨ TỰ',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 8.h),

                            if (!_isPrinting) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Số tiếp theo: ${_getNextNumber(config)}',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Statistics panel
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Color(AppConstants.colors['primary']!)),
                        SizedBox(width: 8.w),
                        Text(
                          'THỐNG KÊ HÔM NAY',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(AppConstants.colors['primary']!),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        children: [
                          _buildStatCard('Tổng số', '${_todayStats['total'] ?? 0}', Icons.receipt_long, Colors.blue),
                          _buildStatCard('Đang chờ', '${_todayStats['waiting'] ?? 0}', Icons.hourglass_empty, Colors.orange),
                          _buildStatCard('Phục vụ', '${_todayStats['serving'] ?? 0}', Icons.support_agent, Colors.green),
                          _buildStatCard('Hoàn thành', '${_todayStats['completed'] ?? 0}', Icons.check_circle, Colors.teal),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Quick actions
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THAO TÁC NHANH',
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
                        child: ElevatedButton.icon(
                          onPressed: _showPrintTestDialog,
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Test In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.all(12.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showResetDialog,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.all(12.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueuePanel() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Card(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.list, color: Color(AppConstants.colors['primary']!)),
                  SizedBox(width: 8.w),
                  Text(
                    'DANH SÁCH PHIẾU HÔM NAY',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(AppConstants.colors['primary']!),
                    ),
                  ),
                  const Spacer(),

                  // Filter buttons
                  _buildFilterChip('Tất cả', _todayQueue.length),
                  SizedBox(width: 8.w),
                  _buildFilterChip('Chờ', _todayStats['waiting'] ?? 0),

                  SizedBox(width: 16.w),

                  if (_isLoading)
                    SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            // Queue list
            Expanded(
              child: _todayQueue.isEmpty
                  ? _buildEmptyQueueView()
                  : ListView.builder(
                padding: EdgeInsets.all(8.w),
                itemCount: _todayQueue.length,
                itemBuilder: (context, index) {
                  final item = _todayQueue[_todayQueue.length - 1 - index]; // Reverse order
                  return _buildQueueItem(item, index == 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Color(AppConstants.colors['primary']!).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(AppConstants.colors['primary']!).withOpacity(0.3)),
      ),
      child: Text(
        '$label ($count)',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Color(AppConstants.colors['primary']!),
        ),
      ),
    );
  }

  Widget _buildEmptyQueueView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Chưa có phiếu nào hôm nay',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Nhấn nút "IN PHIẾU" để bắt đầu',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(QueueItem item, bool isLatest) {
    final statusColor = _getStatusColor(item.status);
    final statusText = item.statusDisplayText;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      elevation: isLatest ? 4 : 1,
      color: isLatest ? Colors.green.withOpacity(0.05) : null,
      child: ListTile(
        leading: Container(
          width: 50.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: isLatest ? Colors.green : Color(AppConstants.colors['primary']!),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isLatest ? [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              item.displayNumber,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),

        title: Row(
          children: [
            Text(
              'Số ${item.displayNumber}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
            if (isLatest) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MỚI NHẤT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tạo lúc: ${DateFormat('HH:mm:ss').format(item.createdTime)}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            if (item.notes?.isNotEmpty == true)
              Text(
                'Ghi chú: ${item.notes}',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
              ),
          ],
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.sp,
                ),
              ),
            ),
            if (item.priority > 0) ...[
              SizedBox(height: 4.h),
              Icon(
                Icons.priority_high,
                color: Colors.red,
                size: 16.w,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationNeeded() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Card(
          margin: EdgeInsets.all(32.w),
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings,
                  size: 64.w,
                  color: Colors.orange,
                ),
                SizedBox(height: 24.h),
                Text(
                  'CẦN CẤU HÌNH THIẾT BỊ',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Thiết bị chưa được cấu hình hoặc cấu hình không hợp lệ.\nVui lòng cấu hình lại để sử dụng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32.h),
                ActionButton(
                  text: 'CẤU HÌNH NGAY',
                  icon: Icons.settings,
                  backgroundColor: Colors.orange,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const SetupScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'refresh',
          onPressed: _loadTodayData,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
        SizedBox(height: 16.h),
        FloatingActionButton.extended(
          heroTag: 'print',
          onPressed: _isPrinting ? null : _printTicket,
          backgroundColor: Color(AppConstants.colors['success']!),
          icon: _isPrinting
              ? SizedBox(
            width: 20.w,
            height: 20.h,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Icon(Icons.print, color: Colors.white),
          label: Text(
            _isPrinting ? 'Đang in...' : 'In phiếu',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getConnectionColor() {
    switch (_connectionStatus) {
      case 'CONNECTED':
        return Colors.green;
      case 'ERROR':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getConnectionText() {
    switch (_connectionStatus) {
      case 'CONNECTED':
        return 'Đã kết nối';
      case 'ERROR':
        return 'Lỗi kết nối';
      default:
        return 'Đang kết nối';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Colors.orange;
      case 'serving':
        return Colors.blue;
      case 'called':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'skipped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNextNumber(config) {
    final nextNum = (_todayStats['last_number'] ?? 0) + 1;
    return '${config.queuePrefix}${nextNum.toString().padLeft(3, '0')}';
  }

  // Action methods
  Future<void> _printTicket() async {
    setState(() => _isPrinting = true);

    try {
      final configService = context.read<ConfigService>();
      final config = configService.config;

      if (config == null) {
        throw Exception('Chưa cấu hình thiết bị');
      }

      // Add to database
      final newTicket = await _databaseService.addToQueue(
        prefix: config.queuePrefix,
        operator: 'tablet1',
        notes: 'In từ máy in chính',
      );

      // Simulate printing process
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual printer integration
      await _sendToPrinter(newTicket, config);

      // TODO: Send MQTT message to other devices
      await _sendMqttMessage(newTicket);

      // Refresh data
      await _loadTodayData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text('✅ Đã in phiếu số ${newTicket.displayNumber}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(child: Text('❌ Lỗi in phiếu: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'THỬ LẠI',
              textColor: Colors.white,
              onPressed: _printTicket,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<void> _sendToPrinter(QueueItem ticket, config) async {
    // TODO: Implement actual printer integration
    // This is a placeholder for printer communication
    debugPrint('Printing ticket: ${ticket.displayNumber}');
    debugPrint('Printer: ${config.printerConnectionString}');

    // Simulate printer communication
    await Future.delayed(const Duration(milliseconds: 500));

    // For now, just log the ticket details
    debugPrint('Ticket details:');
    debugPrint('- Number: ${ticket.displayNumber}');
    debugPrint('- Created: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(ticket.createdTime)}');
    debugPrint('- Store: ${config.storeId}');
  }

  Future<void> _sendMqttMessage(QueueItem ticket) async {
    // TODO: Implement MQTT publishing
    // This is a placeholder for MQTT communication
    debugPrint('MQTT: Publishing new ticket ${ticket.displayNumber}');

    // Simulate MQTT message
    final message = {
      'action': 'queue_add',
      'ticket': ticket.toMqttPayload(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    debugPrint('MQTT Message: $message');
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        _showSettingsDialog();
        break;
      case 'info':
        _showDeviceInfo();
        break;
      case 'reconfigure':
        _showReconfigureDialog();
        break;
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.settings, color: Color(AppConstants.colors['primary']!)),
                  SizedBox(width: 8.w),
                  Text(
                    'CÀI ĐẶT',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              _buildSettingsOption(
                'Cấu hình thiết bị',
                'Thay đổi cài đặt MQTT, máy in, hàng đợi',
                Icons.settings_applications,
                    () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SetupScreen()),
                  );
                },
              ),

              const Divider(),

              _buildSettingsOption(
                'Thông tin thiết bị',
                'Xem thông tin chi tiết về thiết bị',
                Icons.info_outline,
                    () {
                  Navigator.of(context).pop();
                  _showDeviceInfo();
                },
              ),

              const Divider(),

              _buildSettingsOption(
                'Test máy in',
                'In thử để kiểm tra máy in',
                Icons.print_outlined,
                    () {
                  Navigator.of(context).pop();
                  _showPrintTestDialog();
                },
              ),

              const Divider(),

              _buildSettingsOption(
                'Reset hàng đợi',
                'Xóa tất cả dữ liệu hàng đợi hôm nay',
                Icons.refresh,
                    () {
                  Navigator.of(context).pop();
                  _showResetDialog();
                },
                isDestructive: true,
              ),

              SizedBox(height: 24.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ĐÓNG'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Color(AppConstants.colors['primary']!),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showDeviceInfo() {
    final configService = context.read<ConfigService>();
    final config = configService.config;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Color(AppConstants.colors['primary']!)),
                  SizedBox(width: 8.w),
                  Text(
                    'THÔNG TIN THIẾT BỊ',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              if (config != null) ...[
                ConfigSummaryCard(
                  title: 'CẤU HÌNH HIỆN TẠI',
                  items: {
                    'Thiết bị:': config.deviceName,
                    'Store ID:': config.storeId,
                    'MQTT Broker:': config.mqttConnectionString,
                    'Máy in:': config.printerConnectionString,
                    'Queue Prefix:': config.queuePrefix,
                    'Cập nhật lần cuối:': DateFormat('dd/MM/yyyy HH:mm').format(config.lastUpdated),
                  },
                ),
                SizedBox(height: 16.h),
              ],

              ConfigSummaryCard(
                title: 'THÔNG TIN HỆ THỐNG',
                items: {
                  'App Version:': AppConstants.appVersion,
                  'Device Type:': AppConstants.deviceType,
                  'Platform:': 'Android',
                  'Database:': 'SQLite',
                  'Communication:': 'MQTT',
                },
              ),

              SizedBox(height: 24.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ĐÓNG'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReconfigureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấu hình lại thiết bị'),
        content: const Text(
          'Bạn có chắc chắn muốn cấu hình lại thiết bị?\n\n'
              'Thao tác này sẽ đưa bạn về màn hình cấu hình để thiết lập lại các thông số kết nối.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SetupScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('CẤU HÌNH LẠI'),
          ),
        ],
      ),
    );
  }

  void _showPrintTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test máy in'),
        content: const Text(
          'In thử phiếu test để kiểm tra kết nối và hoạt động của máy in?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performPrintTest();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('IN TEST'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8.w),
            const Text('Reset hàng đợi'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn reset toàn bộ hàng đợi hôm nay?\n\n'
              '⚠️ Thao tác này sẽ:\n'
              '• Xóa tất cả phiếu đã in hôm nay\n'
              '• Reset số thứ tự về 1\n'
              '• Không thể hoàn tác\n\n'
              'Chỉ nên thực hiện khi cần thiết!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performReset();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('XÁC NHẬN RESET'),
          ),
        ],
      ),
    );
  }

  Future<void> _performPrintTest() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🖨️ Đang gửi lệnh test đến máy in...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // TODO: Implement actual print test
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test in hoàn tất! Kiểm tra máy in.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi test máy in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performReset() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Đang reset hàng đợi...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Reset daily queue
      await _databaseService.resetDailyQueue();

      // Refresh data
      await _loadTodayData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reset hàng đợi thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}