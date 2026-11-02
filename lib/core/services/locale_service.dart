import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/storage_service.dart';

/// Supported Tashkent language codes.
enum AppLanguage {
  uz('uz', "O'zbekcha", '🇺🇿'),
  ru('ru', 'Русский', '🇷🇺'),
  en('en', 'English', '🇺🇸');

  final String code;
  final String displayName;
  final String flag;

  const AppLanguage(this.code, this.displayName, this.flag);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code.toLowerCase().trim(),
      orElse: () => AppLanguage.en,
    );
  }
}

/// Riverpod provider managing active application locale preference.
final appLocaleProvider = NotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<String> {
  @override
  String build() {
    return StorageService.getAppLanguage();
  }

  Future<void> setLocale(String langCode) async {
    final sanitized = AppLanguage.fromCode(langCode).code;
    state = sanitized;
    await StorageService.setAppLanguage(sanitized);
  }
}

/// Trilingual localization engine for Uzbek, Russian, and English.
class LocaleService {
  static const Map<String, Map<String, String>> _translations = {
    'appName': {
      'en': 'Around Tashkent',
      'uz': 'Around Toshkent',
      'ru': 'Around Ташкент',
    },
    'feed': {
      'en': 'Feed',
      'uz': 'Lenta',
      'ru': 'Лента',
    },
    'explore': {
      'en': 'Explore',
      'uz': 'Kashfiyot',
      'ru': 'Поиск',
    },
    'saved': {
      'en': 'Saved',
      'uz': 'Saqlanganlar',
      'ru': 'Сохраненное',
    },
    'profile': {
      'en': 'Profile',
      'uz': 'Profil',
      'ru': 'Профиль',
    },
    'settings': {
      'en': 'Settings',
      'uz': 'Sozlamalar',
      'ru': 'Настройки',
    },
    'morningBrew': {
      'en': 'Morning Brew',
      'uz': 'Tonggi Qahva',
      'ru': 'Утренний Кофе',
    },
    'afternoonFocus': {
      'en': 'Afternoon Focus',
      'uz': 'Kunduzgi Diqqat',
      'ru': 'Дневной Фокус',
    },
    'goldenHour': {
      'en': 'Golden Hour',
      'uz': 'Oltin Soat',
      'ru': 'Золотой Час',
    },
    'lateNightVinyl': {
      'en': 'Late Night Vinyl',
      'uz': 'Tungi Vinil',
      'ru': 'Ночной Винил',
    },
    'tastePassport': {
      'en': 'Tashkent Taste Passport',
      'uz': 'Toshkent Ta’m Pasporti',
      'ru': 'Паспорт Вкуса Ташкента',
    },
    'sharePassport': {
      'en': 'Share Taste Passport',
      'uz': 'Ta’m Pasportini Ulashish',
      'ru': 'Поделиться паспортом',
    },
    'findFriends': {
      'en': 'Find Friends',
      'uz': 'Do‘stlarni Topish',
      'ru': 'Найти друзей',
    },
    'inviteFriends': {
      'en': 'Invite Friends via Link',
      'uz': 'Do‘stlarni Havola Orqali Taklif Qilish',
      'ru': 'Пригласить друзей по ссылке',
    },
    'editProfile': {
      'en': 'Edit Profile',
      'uz': 'Profilni Tahrirlash',
      'ru': 'Редактировать профиль',
    },
    'privacySecurity': {
      'en': 'Privacy & Security',
      'uz': 'Maxfiylik va Xavfsizlik',
      'ru': 'Конфиденциальность',
    },
    'biometricLock': {
      'en': 'Biometric App Lock',
      'uz': 'Biometrik Ilova Qulfi',
      'ru': 'Биометрическая блокировка',
    },
    'appLanguage': {
      'en': 'App Language',
      'uz': 'Ilova Tili',
      'ru': 'Язык приложения',
    },
    'searchHint': {
      'en': 'Search cafés, plov, study spots...',
      'uz': 'Qahvaxonalar, osh, o‘qish joylarini qidirish...',
      'ru': 'Поиск кафе, плова, мест для учебы...',
    },
  };

  /// Looks up localized string for the specified key and language code.
  static String tr(String key, [String? langCode]) {
    final code = langCode ?? StorageService.getAppLanguage();
    final entry = _translations[key];
    if (entry == null) return key;
    return entry[code] ?? entry['en'] ?? key;
  }
}
