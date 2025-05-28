// Archivo: lib/widgets/custom_text_field.dart
// Widget de campo de texto personalizado reutilizable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? prefixText;
  final String? suffixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsetsGeometry? contentPadding;
  final bool filled;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final bool showCharacterCount;
  final bool autofocus;
  final String? initialValue;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.inputFormatters,
    this.contentPadding,
    this.filled = true,
    this.fillColor,
    this.borderRadius,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.showCharacterCount = false,
    this.autofocus = false,
    this.initialValue,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialValue != null && widget.controller == null) {
      _controller.text = widget.initialValue!;
    }
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: widget.focusNode,
          decoration: _buildInputDecoration(context),
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          onFieldSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          style: widget.textStyle ?? _getDefaultTextStyle(context),
          autofocus: widget.autofocus,
          buildCounter: widget.showCharacterCount ? null : _buildCounter,
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);
    
    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hintText,
      prefixText: widget.prefixText,
      suffixText: widget.suffixText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(),
      filled: widget.filled,
      fillColor: widget.fillColor ?? _getDefaultFillColor(context),
      contentPadding: widget.contentPadding ?? _getDefaultContentPadding(),
      
      // Estilos de texto
      labelStyle: widget.labelStyle ?? _getDefaultLabelStyle(context),
      hintStyle: widget.hintStyle ?? _getDefaultHintStyle(context),
      
      // Bordes
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: widget.borderColor ?? theme.dividerColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: widget.borderColor ?? theme.dividerColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: widget.focusedBorderColor ?? theme.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: widget.errorBorderColor ?? theme.colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: widget.errorBorderColor ?? theme.colorScheme.error,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey[600],
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  Widget? _buildCounter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) {
    return null; // Ocultar contador por defecto
  }

  // Estilos por defecto
  TextStyle _getDefaultTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
  }

  TextStyle _getDefaultLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.grey[700],
      fontWeight: FontWeight.w500,
    ) ?? const TextStyle();
  }

  TextStyle _getDefaultHintStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.grey[500],
    ) ?? const TextStyle();
  }

  Color _getDefaultFillColor(BuildContext context) {
    return Colors.grey[50] ?? const Color(0xFFF5F5F5);
  }

  EdgeInsetsGeometry _getDefaultContentPadding() {
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
}

// Variantes específicas del campo de texto

class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const EmailTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Email',
      hintText: hintText ?? 'ejemplo@correo.com',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: const Icon(Icons.email_outlined),
      validator: validator ?? _defaultEmailValidator,
      onChanged: onChanged,
      enabled: enabled,
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }
}

class PasswordTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final bool showStrengthIndicator;

  const PasswordTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.showStrengthIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Contraseña',
      hintText: hintText ?? 'Ingresa tu contraseña',
      obscureText: true,
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.lock_outlined),
      validator: validator ?? _defaultPasswordValidator,
      onChanged: onChanged,
      enabled: enabled,
    );
  }

  String? _defaultPasswordValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
}

class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const PhoneTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Teléfono',
      hintText: hintText ?? '+52 123 456 7890',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      prefixIcon: const Icon(Icons.phone_outlined),
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;

  const SearchTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText ?? 'Buscar...',
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      autofocus: autofocus,
    );
  }
}

class NumberTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? prefixText;
  final String? suffixText;
  final double? min;
  final double? max;
  final int decimals;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const NumberTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixText,
    this.suffixText,
    this.min,
    this.max,
    this.decimals = 0,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      prefixText: prefixText,
      suffixText: suffixText,
      keyboardType: TextInputType.numberWithOptions(
        decimal: decimals > 0,
        signed: min != null && min! < 0,
      ),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimals > 0 
              ? RegExp(r'^\d*\.?\d*$')
              : RegExp(r'^\d*$'),
        ),
      ],
      validator: validator ?? _defaultNumberValidator,
      onChanged: onChanged,
      enabled: enabled,
    );
  }

  String? _defaultNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Ingresa un número válido';
    }
    
    if (min != null && number < min!) {
      return 'El valor debe ser mayor o igual a $min';
    }
    
    if (max != null && number > max!) {
      return 'El valor debe ser menor o igual a $max';
    }
    
    return null;
  }
}

class TextAreaField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final bool showCharacterCount;

  const TextAreaField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.maxLines = 4,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.showCharacterCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: TextInputAction.newline,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      showCharacterCount: showCharacterCount,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}