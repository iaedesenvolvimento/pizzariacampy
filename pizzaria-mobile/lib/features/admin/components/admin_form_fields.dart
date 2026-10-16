import 'package:flutter/material.dart';

class AdminTextField extends StatelessWidget {
  const AdminTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class AdminCurrencyField extends AdminTextField {
  const AdminCurrencyField({
    required super.controller,
    required super.label,
    super.validator,
    super.onChanged,
    super.key,
  }) : super(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        );
}
