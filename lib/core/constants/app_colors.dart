import 'package:flutter/material.dart';

class AppColors {
  // Paper & Canvas
  static const Color paper = Color(0xFFFBFAF6);
  static const Color paper2 = Color(0xFFF1EEE4);
  static const Color paper3 = Color(0xFFE6E1D3);

  // Typography & Borders
  static const Color ink = Color(0xFF15130F);
  static const Color ink2 = Color(0xFF575247);
  static const Color ink3 = Color(0xFF8E8877);

  // Accent & Brand Colors
  static const Color orange = Color(0xFFFF5A1F); // Signal Orange
  static const Color butter = Color(0xFFFFE07A); // Friends Yellow
  static const Color cobalt = Color(0xFF2B4CFF); // Deep Cobalt
  static const Color mint = Color(0xFFD5E8CB);   // Fresh Mint
  static const Color water = Color(0xFFD7E3EC);  // Soft Sky
  static const Color blush = Color(0xFFF6D2C4);  // Warm Blush
  static const Color danger = Color(0xFFB3261E); // Safety Red

  // Shadow specifications
  static const BoxShadow shadowSm = BoxShadow(
    color: ink,
    offset: Offset(2, 2),
    blurRadius: 0,
  );

  static const BoxShadow shadow = BoxShadow(
    color: ink,
    offset: Offset(3, 3),
    blurRadius: 0,
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: ink,
    offset: Offset(5, 5),
    blurRadius: 0,
  );
}
