// Archivo: lib/widgets/custom_button.dart
// Widget de botón personalizado reutilizable

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final bool enabled;
  final String? loadingText;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.textColor,
    this.icon,
    this.width,
    this.height = 48,
    this.borderRadius = 12,
    this.padding,
    this.textStyle,
    this.enabled = true,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.primaryColor;
    final effectiveTextColor = textColor ?? 
        (isOutlined ? primaryColor : Colors.white);
    
    final isDisabled = !enabled || isLoading || onPressed == null;

    return SizedBox(
      width: width,
      height: height,
      child: isOutlined ? _buildOutlinedButton(
        context,
        primaryColor,
        effectiveTextColor,
        isDisabled,
      ) : _buildElevatedButton(
        context,
        primaryColor,
        effectiveTextColor,
        isDisabled,
      ),
    );
  }

  Widget _buildElevatedButton(
    BuildContext context,
    Color primaryColor,
    Color effectiveTextColor,
    bool isDisabled,
  ) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled 
            ? Colors.grey[300]
            : primaryColor,
        foregroundColor: isDisabled 
            ? Colors.grey[600]
            : effectiveTextColor,
        elevation: isDisabled ? 0 : 2,
        shadowColor: primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: _buildButtonContent(effectiveTextColor, isDisabled),
    );
  }

  Widget _buildOutlinedButton(
    BuildContext context,
    Color primaryColor,
    Color effectiveTextColor,
    bool isDisabled,
  ) {
    return OutlinedButton(
      onPressed: isDisabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDisabled 
            ? Colors.grey[600]
            : effectiveTextColor,
        side: BorderSide(
          color: isDisabled 
              ? Colors.grey[300]!
              : primaryColor,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: _buildButtonContent(effectiveTextColor, isDisabled),
    );
  }

  Widget _buildButtonContent(Color effectiveTextColor, bool isDisabled) {
    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDisabled ? Colors.grey[600]! : effectiveTextColor,
              ),
            ),
          ),
          if (loadingText != null) ...[
            const SizedBox(width: 12),
            Text(
              loadingText!,
              style: _getTextStyle(effectiveTextColor, isDisabled),
            ),
          ],
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDisabled ? Colors.grey[600] : effectiveTextColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: _getTextStyle(effectiveTextColor, isDisabled),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: _getTextStyle(effectiveTextColor, isDisabled),
      overflow: TextOverflow.ellipsis,
    );
  }

  TextStyle _getTextStyle(Color effectiveTextColor, bool isDisabled) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isDisabled ? Colors.grey[600] : effectiveTextColor,
    ).merge(textStyle);
  }
}

// Variantes específicas del botón para casos comunes

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final String? loadingText;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      loadingText: loadingText,
      color: Theme.of(context).primaryColor,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final String? loadingText;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      loadingText: loadingText,
      isOutlined: true,
      color: Theme.of(context).primaryColor,
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final bool isOutlined;
  final String? loadingText;

  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.isOutlined = false,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      isOutlined: isOutlined,
      loadingText: loadingText,
      color: Colors.red,
    );
  }
}

class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final bool isOutlined;
  final String? loadingText;

  const SuccessButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.isOutlined = false,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      isOutlined: isOutlined,
      loadingText: loadingText,
      color: Colors.green,
    );
  }
}

// Botón flotante de acción rápida personalizado
class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final String? label;

  const CustomFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        tooltip: tooltip,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      child: Icon(icon),
    );
  }
}

// Botón de acción en filas (para listas)
class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool isLoading;
  final bool isSmall;

  const ActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
    this.isLoading = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      color: color,
      isLoading: isLoading,
      height: isSmall ? 32 : 40,
      borderRadius: isSmall ? 6 : 8,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 8,
      ),
      textStyle: TextStyle(
        fontSize: isSmall ? 12 : 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// Botón con icono solo personalizado
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double padding;
  final BorderRadius? borderRadius;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.padding = 8,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onPressed,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: backgroundColor != null
            ? BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius ?? BorderRadius.circular(8),
              )
            : null,
        child: Icon(
          icon,
          size: size,
          color: color ?? Theme.of(context).iconTheme.color,
        ),
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