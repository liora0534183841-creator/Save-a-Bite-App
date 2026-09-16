import 'package:flutter/material.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';

/// A reusable, highly customizable text field component.
/// 
/// Supports dynamic theming (Light/Dark mode), RTL text alignment, 
/// error handling, and a built-in visibility toggle for password fields.
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.errorText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    // Determine active theme to adjust colors dynamically
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      textAlign: TextAlign.right, 
      style: TextStyle(color: isDark ? Colors.white : Colors.black), // Dynamic text color
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey), // Dynamic hint color
        errorText: widget.errorText,

        // Replaces the standard prefix icon with a visibility toggle for password fields
        prefixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.deepBlue,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : Icon(widget.prefixIcon, color: AppColors.accentBlue),

        filled: true,
        // Adapts background color dynamically to the active theme
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
      ),
    );
  }
}