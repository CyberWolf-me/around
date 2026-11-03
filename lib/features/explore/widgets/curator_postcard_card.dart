import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/curator_postcard_engine.dart';

class CuratorPostcardCard extends StatelessWidget {
  final CuratorPostcard postcard;
  final String languageCode;
  final ValueChanged<CuratorPostcard>? onShare;
  final ValueChanged<PostcardTheme>? onChangeTheme;
  final ValueChanged<PostcardAspectRatio>? onChangeAspectRatio;

  const CuratorPostcardCard({
    super.key,
    required this.postcard,
    this.languageCode = 'en',
    this.onShare,
    this.onChangeTheme,
    this.onChangeAspectRatio,
  });

  Color get _backgroundColor {
    switch (postcard.theme) {
      case PostcardTheme.warmPaper:
        return AppColors.cardSurface;
      case PostcardTheme.darkCarbon:
        return const Color(0xFF1E1C1A);
      case PostcardTheme.matchaMint:
        return const Color(0xFFE8F7F0);
    }
  }

  Color get _textColor {
    switch (postcard.theme) {
      case PostcardTheme.warmPaper:
        return AppColors.ink;
      case PostcardTheme.darkCarbon:
        return Colors.white;
      case PostcardTheme.matchaMint:
        return const Color(0xFF0F3D2E);
    }
  }

  Color get _mutedColor {
    switch (postcard.theme) {
      case PostcardTheme.warmPaper:
        return AppColors.ink3;
      case PostcardTheme.darkCarbon:
        return const Color(0xFFA09B95);
      case PostcardTheme.matchaMint:
        return const Color(0xFF4A7C6B);
    }
  }

  String _t(String key) {
    switch (key) {
      case 'share_telegram':
        return languageCode == 'uz'
            ? 'Telegramga Ulashish'
            : languageCode == 'ru'
                ? 'Поделиться в Telegram'
                : 'Share to Telegram';
      case 'verified_visit':
        return languageCode == 'uz'
            ? 'TASDIQLANGAN TASHRIF'
            : languageCode == 'ru'
                ? 'ПРОВЕРЕННЫЙ ВИЗИТ'
                : 'VERIFIED VISIT';
      case 'curator':
        return languageCode == 'uz' ? 'Kurator' : languageCode == 'ru' ? 'Куратор' : 'Curator';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = CuratorPostcardEngine.getLocalizedReceiptHeader(languageCode);
    final isSquare = postcard.aspectRatio == PostcardAspectRatio.square1x1;

    return Container(
      key: const Key('curator_postcard_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Perforated / Dashed Top Receipt Line
          _buildDashedLine(),
          const SizedBox(height: 12),

          // Receipt Title & Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                header,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.12 * 10,
                  color: _mutedColor,
                ),
              ),
              Text(
                postcard.receiptNumber,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: _mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Venue Name & District Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postcard.placeName,
                      style: TextStyle(
                        fontSize: isSquare ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: _textColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${postcard.district.toUpperCase()} · ${postcard.atmosphereTag}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Cryptographic Seal Stamp
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.orange, width: 1.2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified, size: 16, color: AppColors.orange),
                    const SizedBox(height: 2),
                    Text(
                      postcard.verifiedSeal,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metro Beacon Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('🚇 ', style: TextStyle(fontSize: 12)),
                Text(
                  postcard.nearestSubway,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  _t('verified_visit'),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Curator Signature Row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.orange,
                child: Text(
                  postcard.curatorName.isNotEmpty
                      ? postcard.curatorName.substring(0, 1).toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postcard.curatorName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                      ),
                    ),
                    Text(
                      '@${postcard.curatorHandle} · ${postcard.curatorTier}',
                      style: TextStyle(fontSize: 10, color: _mutedColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.butterSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${postcard.curatorXp} XP',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barcode Graphic Line
          _buildBarcode(),
          const SizedBox(height: 12),

          // Controls & Share Button Row
          Row(
            children: [
              // Theme Toggle
              InkWell(
                key: const Key('postcard_theme_toggle_btn'),
                onTap: () {
                  final nextTheme = PostcardTheme.values[
                    (postcard.theme.index + 1) % PostcardTheme.values.length
                  ];
                  onChangeTheme?.call(nextTheme);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    CuratorPostcardEngine.getLocalizedThemeName(postcard.theme, languageCode),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.ink2),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Aspect Ratio Toggle
              InkWell(
                key: const Key('postcard_ratio_toggle_btn'),
                onTap: () {
                  final nextRatio = postcard.aspectRatio == PostcardAspectRatio.square1x1
                      ? PostcardAspectRatio.story9x16
                      : PostcardAspectRatio.square1x1;
                  onChangeAspectRatio?.call(nextRatio);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    isSquare ? '1:1 Square' : '9:16 Story',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.ink2),
                  ),
                ),
              ),
              const Spacer(),

              // Share CTA Button
              ElevatedButton.icon(
                key: const Key('postcard_share_telegram_btn'),
                onPressed: () => onShare?.call(postcard),
                icon: const Icon(Icons.send, size: 12),
                label: Text(
                  _t('share_telegram'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index.isEven ? AppColors.borderSubtle : Colors.transparent,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBarcode() {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          40,
          (i) => Container(
            width: (i % 3 == 0) ? 2.5 : 1.2,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            color: _mutedColor.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
