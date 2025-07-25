// lib/widgets/action_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final BorderRadius? borderRadius;
  final double elevation;

  const ActionButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.padding,
    this.fontSize,
    this.borderRadius,
    this.elevation = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool canPress = isEnabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton.icon(
        onPressed: canPress ? onPressed : null,
        icon: _buildIcon(),
        label: Text(
          text,
          style: TextStyle(
            fontSize: fontSize ?? 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: padding ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          elevation: canPress ? elevation : 0,
          disabledBackgroundColor: backgroundColor?.withOpacity(0.5) ??
              Theme.of(context).primaryColor.withOpacity(0.5),
          disabledForegroundColor: textColor?.withOpacity(0.5) ??
              Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (isLoading) {
      return SizedBox(
        width: 20.w,
        height: 20.h,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor ?? Colors.white,
          ),
        ),
      );
    }

    return Icon(
      icon,
      size: 20.w,
    );
  }
}

// Specialized button variants
class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: Theme.of(context).primaryColor,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const SecondaryButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: Colors.grey[600],
    );
  }
}

class SuccessButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const SuccessButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: Colors.green[600],
    );
  }
}

class WarningButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const WarningButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: Colors.orange[600],
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const DangerButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: Colors.red[600],
    );
  }
}

// Compact button for small spaces
class CompactActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final bool isLoading;

  const CompactActionButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      isLoading: isLoading,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      fontSize: 12.sp,
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
    );
  }
}

// Icon-only button
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final bool isLoading;
  final double size;

  const IconActionButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.isLoading = false,
    this.size = 48.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button = SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: iconColor ?? Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
          width: 20.w,
          height: 20.h,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              iconColor ?? Colors.white,
            ),
          ),
        )
            : Icon(icon, size: size * 0.5),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}