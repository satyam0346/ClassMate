import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Reusable text field widget for all auth screens.
/// Applies the ClassMate design system automatically.
class AuthTextField extends StatefulWidget {
  final String            label;
  final String?           hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool              obscureText;
  final TextInputType     keyboardType;
  final TextInputAction   textInputAction;
  final Widget?           prefixIcon;
  final Widget?           suffixIcon;
  final int               maxLength;
  final int               maxLines;
  final bool              enabled;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode?        focusNode;
  final bool              autofocus;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.obscureText        = false,
    this.keyboardType       = TextInputType.text,
    this.textInputAction    = TextInputAction.next,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength          = 200,
    this.maxLines           = 1,
    this.enabled            = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus          = false,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller:      widget.controller,
      focusNode:       widget.focusNode,
      autofocus:       widget.autofocus,
      keyboardType:    widget.keyboardType,
      textInputAction: widget.textInputAction,
      enabled:         widget.enabled,
      maxLength:       widget.maxLength,
      maxLines:        widget.maxLines,
      obscureText:     widget.obscureText && _isObscured,
      onChanged:       widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator:       widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText:    widget.label,
        hintText:     widget.hint,
        counterText:  '', // hide maxLength counter
        prefixIcon:   widget.prefixIcon != null
            ? IconTheme(
                data: IconThemeData(
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size:  AppSizes.iconMd,
                ),
                child: widget.prefixIcon!,
              )
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  size: AppSizes.iconMd,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              )
            : widget.suffixIcon,
      ),
    );
  }
}
