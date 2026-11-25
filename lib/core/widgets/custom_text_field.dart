import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefixText;
  final bool isNumeric;
  final bool isDecimal;
  final bool isPassword;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.isNumeric = false,
    this.isDecimal = false,
    this.isPassword = false,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : isNumeric
                  ? TextInputType.number
                  : TextInputType.text,
          inputFormatters: [
            if (isNumeric && !isDecimal) FilteringTextInputFormatter.digitsOnly,
            if (isDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: isDark ? AppColors.secondaryCyan : AppColors.primaryIndigo,
                  )
                : null,
            prefixText: prefixText != null ? "$prefixText " : null,
            prefixStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.secondaryCyan : AppColors.primaryIndigo,
            ),
          ),
        ),
      ],
    );
  }
}
