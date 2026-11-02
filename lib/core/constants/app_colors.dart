import 'package:flutter/material.dart';

class AppColors {
  // Brand Accents
  static const Color orange = Color(0xFFFF4800);
  static const Color butter = Color(0xFFFFD666);
  static const Color mint = Color(0xFF66E5B4);
  static const Color cobalt = Color(0xFF2E5BFF);
  static const Color blush = Color(0xFFFFB4A2);
  static const Color danger = Color(0xFFDC2626);

  // Subtle Tints
  static const Color orangeSubtle = Color(0x1FFF4800);
  static const Color butterSubtle = Color(0x33FFD666);
  static const Color mintSubtle = Color(0x2266E5B4);
  static const Color cobaltSubtle = Color(0x1F2E5BFF);

  // Editorial Paper Surfaces
  static const Color paper = Color(0xFFFAF7F2); // Warm off-white
  static const Color paper2 = Color(0xFFF3ECE0); // Slightly deeper sand/cream
  static const Color paper3 = Color(0xFFE8DECF); // Crisp divider / pill background
  static const Color cardSurface = Color(0xFFFFFDF9); // Pristine illuminated card face
  static const Color surfaceWarm = Color(0xFFF7F2EA); // Rich neutral container

  // Ink Typography Hierarchy
  static const Color ink = Color(0xFF161412); // Deep rich carbon
  static const Color ink2 = Color(0xFF5A544C); // Editorial charcoal secondary
  static const Color ink3 = Color(0xFF8F887F); // Muted metadata/tertiary
  static const Color inkLight = Color(0xFFB8B0A5); // Placeholder & disabled text

  // Refined Hairline Borders
  static const Color borderHairline = Color(0x18161412); // ~9% opacity border
  static const Color borderSubtle = Color(0x28161412); // ~16% opacity border
  static const Color borderMedium = Color(0x44161412); // ~27% opacity border

  // Soft Ambient Shadows
  static const BoxShadow shadowCard = BoxShadow(
    color: Color(0x0C161412),
    blurRadius: 16,
    offset: Offset(0, 4),
    spreadRadius: -2,
  );

  static const BoxShadow shadowFloating = BoxShadow(
    color: Color(0x1A161412),
    blurRadius: 30,
    offset: Offset(0, 10),
    spreadRadius: -2,
  );

  static const BoxShadow shadowSubtle = BoxShadow(
    color: Color(0x08161412),
    blurRadius: 8,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  static const BoxShadow shadowTactile = BoxShadow(
    color: Color(0x12161412),
    offset: Offset(0, 1.5),
    blurRadius: 3,
  );

  // Tactile Offset Shadows (Refined from 3px to 2px for signature tactile components)
  static const BoxShadow shadowSm = BoxShadow(
    color: ink,
    offset: Offset(1.5, 1.5),
    blurRadius: 0,
  );

  static const BoxShadow shadow = BoxShadow(
    color: ink,
    offset: Offset(2.5, 2.5),
    blurRadius: 0,
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: ink,
    offset: Offset(4, 4),
    blurRadius: 0,
  );
}
