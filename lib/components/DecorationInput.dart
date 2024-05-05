import 'package:flutter/material.dart';

InputDecoration getInputDecoration(
  String label, {
  Icon? prefx_icon,
  Icon? sufx_icon,
  IconButton? prefx_iconBtn,
  IconButton? sufx_iconBtn,
  double borderRadius = 0,
  EdgeInsetsGeometry? customPadding,
  String? textHint,
  TextStyle? errorStyle,
}) {
  return InputDecoration(
    hintText: label,
    fillColor: Colors.white,
    filled: true,
    suffixIcon: sufx_icon ?? sufx_iconBtn,
    prefixIcon: prefx_icon ?? prefx_iconBtn,
    contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
    ),
    errorStyle: errorStyle,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: Colors.black, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: Color(0xFF0469ff), width: 4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: Colors.black, width: 2),
    ),
  );
}
