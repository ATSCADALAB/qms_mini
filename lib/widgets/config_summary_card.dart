// lib/widgets/config_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConfigSummaryCard extends StatelessWidget {
  final String title;
  final Map<String, String> items;
  final VoidCallback? onEdit;
  final IconData? titleIcon;
  final Color? titleColor;
  final bool showDividers;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ConfigSummaryCard({
    Key? key,
    required this.title,
    required this.items,
    this.onEdit,
    this.titleIcon,
    this.titleColor,
    this.showDividers = false,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: margin ?? EdgeInsets.symmetric(vertical: 4.h),
      child: Padding(
        padding: padding ?? EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: 12.h),
            ...items.entries.map((entry) => _buildSummaryRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (titleIcon != null) ...[
              Icon(
                titleIcon,
                color: titleColor ?? Theme.of(context).primaryColor,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: titleColor ?? Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit,
              color: titleColor ?? Theme.of(context).primaryColor,
              size: 20.w,
            ),
            padding: EdgeInsets.all(4.w),
            constraints: BoxConstraints(
              minWidth: 32.w,
              minHeight: 32.h,
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120.w,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value.isEmpty ? '(chưa cấu hình)' : value,
                  style: TextStyle(
                    color: value.isEmpty ? Colors.red[600] : Colors.black87,
                    fontSize: 13.sp,
                    fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (showDividers && items.entries.last.key != label) ...[
            SizedBox(height: 6.h),
            Divider(height: 1.h, color: Colors.grey[300]),
          ],
        ],
      ),
    );
  }
}

// Specialized config cards
class DeviceInfoCard extends StatelessWidget {
  final String deviceName;
  final String storeId;
  final String version;
  final String platform;
  final VoidCallback? onEdit;

  const DeviceInfoCard({
    Key? key,
    required this.deviceName,
    required this.storeId,
    required this.version,
    required this.platform,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConfigSummaryCard(
      title: 'THÔNG TIN THIẾT BỊ',
      titleIcon: Icons.tablet_android,
      items: {
        'Tên thiết bị:': deviceName,
        'Store ID:': storeId,
        'Phiên bản:': version,
        'Nền tảng:': platform,
      },
      onEdit: onEdit,
      showDividers: true,
    );
  }
}

class ConnectionInfoCard extends StatelessWidget {
  final String mqttBroker;
  final String mqttPort;
  final String printerIP;
  final String printerPort;
  final VoidCallback? onEdit;

  const ConnectionInfoCard({
    Key? key,
    required this.mqttBroker,
    required this.mqttPort,
    required this.printerIP,
    required this.printerPort,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConfigSummaryCard(
      title: 'THÔNG TIN KẾT NỐI',
      titleIcon: Icons.wifi,
      items: {
        'MQTT Broker:': '$mqttBroker:$mqttPort',
        'Máy in:': '$printerIP:$printerPort',
      },
      onEdit: onEdit,
      showDividers: true,
    );
  }
}

class QueueSettingsCard extends StatelessWidget {
  final String prefix;
  final String startNumber;
  final String resetTime;
  final VoidCallback? onEdit;

  const QueueSettingsCard({
    Key? key,
    required this.prefix,
    required this.startNumber,
    required this.resetTime,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConfigSummaryCard(
      title: 'CẤU HÌNH HÀNG ĐỢI',
      titleIcon: Icons.format_list_numbered,
      items: {
        'Prefix:': prefix,
        'Số bắt đầu:': startNumber,
        'Reset lúc:': resetTime.isEmpty ? 'Không reset' : resetTime,
      },
      onEdit: onEdit,
      showDividers: true,
    );
  }
}

// Status summary card with colored indicators
class StatusSummaryCard extends StatelessWidget {
  final String title;
  final Map<String, StatusInfo> statusItems;
  final VoidCallback? onRefresh;

  const StatusSummaryCard({
    Key? key,
    required this.title,
    required this.statusItems,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                      size: 20.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).primaryColor,
                      size: 20.w,
                    ),
                    padding: EdgeInsets.all(4.w),
                    constraints: BoxConstraints(
                      minWidth: 32.w,
                      minHeight: 32.h,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            ...statusItems.entries.map((entry) => _buildStatusRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, StatusInfo status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: status.color, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  status.text,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data class for status information
class StatusInfo {
  final String text;
  final Color color;
  final IconData? icon;

  const StatusInfo({
    required this.text,
    required this.color,
    this.icon,
  });

  // Factory constructors for common statuses
  factory StatusInfo.success(String text) {
    return StatusInfo(text: text, color: Colors.green);
  }

  factory StatusInfo.error(String text) {
    return StatusInfo(text: text, color: Colors.red);
  }

  factory StatusInfo.warning(String text) {
    return StatusInfo(text: text, color: Colors.orange);
  }

  factory StatusInfo.info(String text) {
    return StatusInfo(text: text, color: Colors.blue);
  }

  factory StatusInfo.neutral(String text) {
    return StatusInfo(text: text, color: Colors.grey);
  }
}

// Statistics card for numerical data
class StatsCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> stats;
  final IconData? titleIcon;
  final Color? accentColor;

  const StatsCard({
    Key? key,
    required this.title,
    required this.stats,
    this.titleIcon,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).primaryColor;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, color: color, size: 20.w),
                  SizedBox(width: 8.w),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...stats.entries.map((entry) => _buildStatRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: accentColor ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}