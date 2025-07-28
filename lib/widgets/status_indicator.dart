import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusIndicator extends StatelessWidget {
  final String label;
  final String status;
  final IconData? icon;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const StatusIndicator({
    super.key,
    required this.label,
    required this.status,
    this.icon,
    this.showIcon = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color color = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    return Padding(
      padding: padding ?? EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null && showIcon) ...[
                Icon(icon, size: 20.w, color: Colors.grey[600]),
                SizedBox(width: 8.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  color: color,
                  size: 16.w,
                ),
                SizedBox(width: 6.w),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'OK':
      case 'ĐÃ LƯU':
      case 'CONNECTED':
      case 'SUCCESS':
        return Colors.green;
      case 'ERROR':
      case 'FAILED':
      case 'DISCONNECTED':
      case 'OFFLINE':
        return Colors.red;
      case 'ĐANG TEST...':
      case 'CONNECTING...':
      case 'LOADING...':
      case 'TESTING':
        return Colors.orange;
      case 'CHƯA TEST':
      case 'CHƯA LƯU':
      case 'NOT SET':
      case 'PENDING':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'OK':
      case 'ĐÃ LƯU':
      case 'CONNECTED':
      case 'SUCCESS':
        return Icons.check_circle;
      case 'ERROR':
      case 'FAILED':
      case 'DISCONNECTED':
      case 'OFFLINE':
        return Icons.error;
      case 'ĐANG TEST...':
      case 'CONNECTING...':
      case 'LOADING...':
      case 'TESTING':
        return Icons.refresh;
      case 'CHƯA TEST':
      case 'CHƯA LƯU':
      case 'NOT SET':
      case 'PENDING':
        return Icons.help_outline;
      default:
        return Icons.info_outline;
    }
  }
}

//--- Các widget chuyên biệt có thể đặt cùng file hoặc tách riêng ---//

class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? customText;
  final VoidCallback? onTap;

  const ConnectionStatusIndicator({
    super.key,
    required this.isConnected,
    this.customText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: StatusIndicator(
        label: 'Kết nối',
        status: customText ?? (isConnected ? 'CONNECTED' : 'DISCONNECTED'),
        icon: Icons.wifi,
      ),
    );
  }
}

class PrinterStatusIndicator extends StatelessWidget {
  final String status;
  final VoidCallback? onTest;

  const PrinterStatusIndicator({
    super.key,
    required this.status,
    this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTest,
      child: StatusIndicator(
        label: 'Máy in',
        status: status,
        icon: Icons.print,
      ),
    );
  }
}

class ConfigStatusIndicator extends StatelessWidget {
  final bool isConfigured;
  final VoidCallback? onConfigure;

  const ConfigStatusIndicator({
    super.key,
    required this.isConfigured,
    this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onConfigure,
      child: StatusIndicator(
        label: 'Cấu hình',
        status: isConfigured ? 'ĐÃ LƯU' : 'CHƯA LƯU',
        icon: Icons.settings,
      ),
    );
  }
}