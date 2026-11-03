import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/telegram_deep_link_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Interactive Telegram Mini App Share Sheet Widget (`P29-02`).
/// Displays structured deep links into the Telegram bot Mini App,
/// offers 1-tap clipboard copying, and triggers Telegram social sharing.
class TelegramShareSheet extends StatefulWidget {
  final TelegramDeepLinkType type;
  final String resourceId;
  final String title;
  final String subtitle;
  final String? referrerId;
  final String languageCode;
  final VoidCallback? onCopyLink;
  final ValueChanged<String>? onShareToTelegram;

  const TelegramShareSheet({
    super.key,
    required this.type,
    required this.resourceId,
    required this.title,
    this.subtitle = '',
    this.referrerId,
    this.languageCode = 'en',
    this.onCopyLink,
    this.onShareToTelegram,
  });

  @override
  State<TelegramShareSheet> createState() => _TelegramShareSheetState();
}

class _TelegramShareSheetState extends State<TelegramShareSheet> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final lang = widget.languageCode.toLowerCase();
    final linkUrl = TelegramDeepLinkEngine.buildBotUrl(
      type: widget.type,
      resourceId: widget.resourceId,
      referrerId: widget.referrerId,
    );

    final shareText = TelegramDeepLinkEngine.formatShareMessage(
      type: widget.type,
      title: widget.title,
      url: linkUrl,
      language: lang,
    );

    String sheetTitle;
    String copyLabel;
    String copiedLabel;
    String shareBtnLabel;

    switch (lang) {
      case 'uz':
        sheetTitle = 'Telegramda Ulashish';
        copyLabel = 'Nusxa Olish';
        copiedLabel = 'Nusxalandi!';
        shareBtnLabel = 'Telegramga Yuborish';
        break;
      case 'ru':
        sheetTitle = 'Поделиться в Telegram';
        copyLabel = 'Копировать';
        copiedLabel = 'Скопировано!';
        shareBtnLabel = 'Отправить в Telegram';
        break;
      case 'en':
      default:
        sheetTitle = 'Share to Telegram';
        copyLabel = 'Copy Link';
        copiedLabel = 'Copied!';
        shareBtnLabel = 'Send via Telegram';
        break;
    }

    return Container(
      key: const Key('telegram_share_sheet'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.paper3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E5BFF).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('✈️', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TELEGRAM MINI APP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E5BFF),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sheetTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content Preview Card
          Container(
            key: const Key('telegram_preview_card'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (widget.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // URL Pill with Copy button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          linkUrl,
                          style: GoogleFonts.firaCode(
                            fontSize: 11,
                            color: AppColors.ink2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        key: const Key('copy_link_btn'),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: linkUrl));
                          HapticService.selection();
                          setState(() {
                            _copied = true;
                          });
                          widget.onCopyLink?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _copied ? AppColors.mintSubtle : AppColors.paper2,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _copied ? AppColors.mint : AppColors.borderSubtle,
                            ),
                          ),
                          child: Text(
                            _copied ? copiedLabel : copyLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _copied ? AppColors.mint : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('send_telegram_btn'),
              onPressed: () {
                HapticService.success();
                widget.onShareToTelegram?.call(shareText);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E5BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✈️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    shareBtnLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
