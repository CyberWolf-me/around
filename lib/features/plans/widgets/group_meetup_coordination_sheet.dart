import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/subway_proximity_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Interactive modal sheet for coordinating small group meetups (3-6 curators) (`P22-02`).
/// Integrates venue selection, metro station beacon, date/time pickers,
/// and pre-formats Telegram group RSVP invite links.
class GroupMeetupCoordinationSheet extends StatefulWidget {
  final String venueName;
  final String venueSlug;
  final double? venueLatitude;
  final double? venueLongitude;
  final String initialOccasion;
  final DateTime? initialDateTime;
  final int initialMaxParticipants;
  final String languageCode;
  final void Function(String url)? onLaunchOverride;
  final void Function(String occasion, DateTime dateTime, int maxParticipants)? onPlanCreated;

  const GroupMeetupCoordinationSheet({
    super.key,
    required this.venueName,
    this.venueSlug = 'breadly',
    this.venueLatitude,
    this.venueLongitude,
    this.initialOccasion = 'Saturday Coffee & Pastries',
    this.initialDateTime,
    this.initialMaxParticipants = 4,
    this.languageCode = 'en',
    this.onLaunchOverride,
    this.onPlanCreated,
  });

  /// Presents the Group Meetup Coordination bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String venueName,
    String venueSlug = 'breadly',
    double? venueLatitude,
    double? venueLongitude,
    String initialOccasion = 'Saturday Coffee & Pastries',
    DateTime? initialDateTime,
    int initialMaxParticipants = 4,
    String languageCode = 'en',
    void Function(String url)? onLaunchOverride,
    void Function(String occasion, DateTime dateTime, int maxParticipants)? onPlanCreated,
  }) {
    HapticService.selection();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GroupMeetupCoordinationSheet(
        venueName: venueName,
        venueSlug: venueSlug,
        venueLatitude: venueLatitude,
        venueLongitude: venueLongitude,
        initialOccasion: initialOccasion,
        initialDateTime: initialDateTime,
        initialMaxParticipants: initialMaxParticipants,
        languageCode: languageCode,
        onLaunchOverride: onLaunchOverride,
        onPlanCreated: onPlanCreated,
      ),
    );
  }

  /// Builds conversational group invite text for Telegram groups and chats.
  static String buildGroupInviteMessage({
    required String occasion,
    required String venueName,
    required String timeFormatted,
    required int maxParticipants,
    required String venueSlug,
    String? metroBeacon,
    String lang = 'en',
  }) {
    final deepLink = 'https://around.tashkent.app/places/$venueSlug';
    final metroLine = metroBeacon != null && metroBeacon.isNotEmpty ? '\nTransit: $metroBeacon' : '';

    switch (lang.toLowerCase()) {
      case 'uz':
        return '☕ Toshkent Do‘stlar Uchrashuvi: $occasion\n'
            'Joy: $venueName$metroLine\n'
            'Vaqt: $timeFormatted\n'
            'Guruh hajmi: $maxParticipants kishi\n'
            'Around orqali tasdiqlang: $deepLink';
      case 'ru':
        return '☕ Встреча друзей в Ташкенте: $occasion\n'
            'Место: $venueName$metroLine\n'
            'Время: $timeFormatted\n'
            'Ограничение: $maxParticipants чел.\n'
            'Подтвердить в Around: $deepLink';
      case 'en':
      default:
        return '☕ Tashkent Friends Meetup: $occasion\n'
            'Place: $venueName$metroLine\n'
            'Time: $timeFormatted\n'
            'Group size: $maxParticipants curators\n'
            'RSVP on Around: $deepLink';
    }
  }

  /// Builds Telegram share URL.
  static Uri buildTelegramShareUri({
    required String message,
    required String venueSlug,
  }) {
    final deepLink = 'https://around.tashkent.app/places/$venueSlug';
    return Uri.https('t.me', '/share/url', {
      'url': deepLink,
      'text': message,
    });
  }

  @override
  State<GroupMeetupCoordinationSheet> createState() => _GroupMeetupCoordinationSheetState();
}

class _GroupMeetupCoordinationSheetState extends State<GroupMeetupCoordinationSheet> {
  late TextEditingController _occasionController;
  late DateTime _selectedDateTime;
  late int _maxParticipants;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _occasionController = TextEditingController(text: widget.initialOccasion);
    _selectedDateTime = widget.initialDateTime ??
        DateTime.now().add(const Duration(days: 1)).copyWith(hour: 11, minute: 0);
    _maxParticipants = widget.initialMaxParticipants.clamp(2, 10);
  }

  @override
  void dispose() {
    _occasionController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour:$minute';
  }

  String? _getMetroBeacon() {
    if (widget.venueLatitude == null || widget.venueLongitude == null) return null;
    final match = SubwayProximityEngine.findClosestStation(
      widget.venueLatitude!,
      widget.venueLongitude!,
    );
    return match.getFormattedBadge(lang: widget.languageCode);
  }

  Future<void> _handleShareTelegram(String inviteMessage, Uri telegramUri) async {
    HapticService.selection();
    if (widget.onLaunchOverride != null) {
      widget.onLaunchOverride!(telegramUri.toString());
      return;
    }
    if (await canLaunchUrl(telegramUri)) {
      await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleCopy(String text) async {
    HapticService.selection();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final metroBeacon = _getMetroBeacon();
    final timeStr = _formatDateTime(_selectedDateTime);
    final inviteMessage = GroupMeetupCoordinationSheet.buildGroupInviteMessage(
      occasion: _occasionController.text.trim().isNotEmpty
          ? _occasionController.text.trim()
          : widget.initialOccasion,
      venueName: widget.venueName,
      timeFormatted: timeStr,
      maxParticipants: _maxParticipants,
      venueSlug: widget.venueSlug,
      metroBeacon: metroBeacon,
      lang: widget.languageCode,
    );

    final telegramUri = GroupMeetupCoordinationSheet.buildTelegramShareUri(
      message: inviteMessage,
      venueSlug: widget.venueSlug,
    );

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
          boxShadow: const [AppColors.shadowFloating],
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.inkLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.orangeSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('☕', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GROUP COFFEE MEETUP',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.inkLight),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Venue & Transit Banner
              Container(
                width: double.infinity,
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
                      widget.venueName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    if (metroBeacon != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        metroBeacon,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.ink3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Occasion Input
              Text(
                'Occasion / Topic',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _occasionController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. Saturday Coffee & Pastries',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.ink),
              ),
              const SizedBox(height: 14),

              // Group Size Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Curator Limit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: _maxParticipants > 2
                            ? () {
                                HapticService.selection();
                                setState(() => _maxParticipants--);
                              }
                            : null,
                      ),
                      Text(
                        '$_maxParticipants curators',
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: _maxParticipants < 10
                            ? () {
                                HapticService.selection();
                                setState(() => _maxParticipants++);
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Preview Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  inviteMessage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.orange,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleCopy(inviteMessage),
                      icon: Icon(
                        _copied ? Icons.check : Icons.copy,
                        size: 16,
                        color: _copied ? AppColors.orange : AppColors.ink,
                      ),
                      label: Text(
                        _copied ? 'Copied!' : 'Copy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _copied ? AppColors.orange : AppColors.ink,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleShareTelegram(inviteMessage, telegramUri),
                      icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      label: Text(
                        'Share to Telegram',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF229ED9), // Telegram Blue
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Confirm Plan Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    HapticService.selection();
                    if (widget.onPlanCreated != null) {
                      widget.onPlanCreated!(
                        _occasionController.text.trim(),
                        _selectedDateTime,
                        _maxParticipants,
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Save Meetup to Plans',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
