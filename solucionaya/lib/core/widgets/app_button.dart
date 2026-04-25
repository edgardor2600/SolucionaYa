import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Botón primario reutilizable con soporte para estados:
/// normal, loading, disabled y outlined.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = backgroundColor ??
        (isOutlined ? Colors.transparent : colorScheme.primary);
    final fgColor = textColor ??
        (isOutlined ? colorScheme.primary : colorScheme.onPrimary);

    final style = isOutlined
        ? OutlinedButton.styleFrom(
            minimumSize: Size(width ?? double.infinity, height),
            side: BorderSide(color: colorScheme.primary, width: 1.5),
            foregroundColor: fgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          )
        : ElevatedButton.styleFrom(
            minimumSize: Size(width ?? double.infinity, height),
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            disabledBackgroundColor: AppColors.borderLight,
            disabledForegroundColor: AppColors.textDisabled,
            elevation: _isDisabled ? 0 : AppDimensions.elevationSm,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          );

    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimensions.iconSm + 2),
                const SizedBox(width: AppDimensions.spacingXs),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppDimensions.fontMd,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: _isDisabled ? null : onPressed,
        style: style,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: _isDisabled ? null : onPressed,
      style: style,
      child: child,
    );
  }
}
