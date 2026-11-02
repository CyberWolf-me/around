import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? overlay;

  const AppImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (path.startsWith('data:image/')) {
      final commaIdx = path.indexOf(',');
      if (commaIdx != -1) {
        try {
          final bytes = base64Decode(path.substring(commaIdx + 1));
          imageWidget = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _errorPlaceholder(),
          );
        } catch (_) {
          imageWidget = _errorPlaceholder();
        }
      } else {
        imageWidget = _errorPlaceholder();
      }
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      imageWidget = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.paper2,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
              ),
            ),
          );
        },
      );
    } else if (!kIsWeb && (path.startsWith('/') || path.contains(':\\') || path.startsWith('file://'))) {
      final cleanPath = path.replaceFirst('file://', '');
      imageWidget = Image.file(
        File(cleanPath),
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    } else {
      // Asset fallback
      imageWidget = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }

    if (overlay != null) {
      imageWidget = Stack(
        fit: StackFit.passthrough,
        children: [
          imageWidget,
          overlay!,
        ],
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _errorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.paper2,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.inkLight.withValues(alpha: 0.6),
          size: 24,
        ),
      ),
    );
  }
}
