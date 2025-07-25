// lib/widgets/status_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusIndicator extends StatelessWidget {
  final String label;
  final String status;
  final IconData? icon;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const StatusIndicator({
    Key? key,
    required this.label,
    required this.status,
    this.icon,
    this.showIcon = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = _getStatusColor();
    IconData statusIcon = _getStatusIcon();

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

  Color _getStatusColor() {
    switch (status.toUpperCase()) {
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

  IconData _getStatusIcon() {
    switch (status.toUpperCase()) {
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

// Specialized status indicators
class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? customText;
  final VoidCallback? onTap;

  const ConnectionStatusIndicator({
    Key? key,
    required this.isConnected,
    this.customText,
    this.onTap,
  }) : super(key: key);

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
    Key? key,
    required this.status,
    this.onTest,
  }) : super(key: key);

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
    Key? key,
    required this.isConfigured,
    this.onConfigure,
  }) : super(key: key);

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
case 'ĐÃ LƯU':
case 'CONNECTED':
return Colors.green;
case 'ERROR':
case 'FAILED':
case 'DISCONNECTED':
return Colors.red;
case 'ĐANG TEST...':
case 'CONNECTING...':
case 'LOADING...':
return Colors.orange;
case 'CHƯA TEST':
case 'CHƯA LƯU':
case 'NOT SET':
return Colors.grey;
default:
return Colors.blue;
}
}

IconData _getStatusIcon() {
  switch (status.toUpperCase()) {
    case 'OK':
    case 'ĐÃ LƯU':
    case 'CONNECTED':
      return Icons.check_circle;
    case 'ERROR':
    case 'FAILED':
    case 'DISCONNECTED':
      return Icons.error;
    case 'ĐANG TEST...':
    case 'CONNECTING...':
    case 'LOADING...':
      return Icons.refresh;
    case 'CHƯA TEST':
    case 'CHƯA LƯU':
    case 'NOT SET':
      return Icons.help_outline;
    default:
      return Icons.info_outline;
  }
}
}

// lib/widgets/config_summary_card.dart
class ConfigSummaryCard extends StatelessWidget {
  final String title;
  final Map<String, String> items;
  final VoidCallback? onEdit;

  const ConfigSummaryCard({
    Key? key,
    required this.title,
    required this.items,
    this.onEdit,
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    color: Colors.blue[700],
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            ...items.entries.map((entry) => _buildSummaryRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }
}

// lib/widgets/connection_test_card.dart
class ConnectionTestCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Future<bool> Function() testFunction;
  final String successMessage;
  final String errorMessage;

  const ConnectionTestCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.testFunction,
    required this.successMessage,
    required this.errorMessage,
  }) : super(key: key);

  @override
  State<ConnectionTestCard> createState() => _ConnectionTestCardState();
}

class _ConnectionTestCardState extends State<ConnectionTestCard> {
  String _status = 'CHƯA TEST';
  bool _isTesting = false;

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
              children: [
                Icon(widget.icon, color: Colors.blue[700]),
                SizedBox(width: 8.w),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            StatusIndicator(label: 'Trạng thái', status: _status),
            SizedBox(height: 16.h),
            ActionButton(
              text: 'TEST KẾT NỐI',
              icon: Icons.wifi_find,
              backgroundColor: Colors.orange,
              isLoading: _isTesting,
              onPressed: _testConnection,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _status = 'ĐANG TEST...';
    });

    try {
      final result = await widget.testFunction();
      setState(() {
        _status = result ? 'OK' : 'ERROR';
        _isTesting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? widget.successMessage : widget.errorMessage),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'ERROR';
        _isTesting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.errorMessage}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

Widget _buildSummaryRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
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
              color: value.isEmpty ? Colors.red : Colors.black87,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    ),
  );
}
}

// lib/widgets/action_button.dart
class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool isEnabled;

  const ActionButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        icon: isLoading
            ? SizedBox(
          width: 20.w,
          height: 20.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.blue[700],
          foregroundColor: textColor ?? Colors.white,
          padding: EdgeInsets.all(16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isEnabled ? 2 : 0,
        ),
      ),
    );
  }