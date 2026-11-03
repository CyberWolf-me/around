import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available Telegram bot slash commands for Around Tashkent.
enum TelegramBotCommand {
  start,
  passport,
  trophies,
  routes,
  help,
  unknown;

  static TelegramBotCommand fromString(String raw) {
    final clean = raw.trim().toLowerCase();
    if (clean.startsWith('/start')) return TelegramBotCommand.start;
    if (clean.startsWith('/passport')) return TelegramBotCommand.passport;
    if (clean.startsWith('/trophies') || clean.startsWith('/trophy')) return TelegramBotCommand.trophies;
    if (clean.startsWith('/routes') || clean.startsWith('/route')) return TelegramBotCommand.routes;
    if (clean.startsWith('/help')) return TelegramBotCommand.help;
    return TelegramBotCommand.unknown;
  }
}

/// An inline keyboard button for Telegram Bot API messages.
class TelegramInlineButton {
  final String text;
  final String? webAppUrl;
  final String? url;

  const TelegramInlineButton({
    required this.text,
    this.webAppUrl,
    this.url,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'text': text};
    if (webAppUrl != null) {
      map['web_app'] = {'url': webAppUrl};
    } else if (url != null) {
      map['url'] = url;
    }
    return map;
  }
}

/// A Telegram message payload containing Markdown formatted text and inline buttons.
class TelegramBotReply {
  final String text;
  final List<List<TelegramInlineButton>> inlineKeyboard;
  final TelegramBotCommand command;

  const TelegramBotReply({
    required this.text,
    required this.inlineKeyboard,
    required this.command,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'parse_mode': 'Markdown',
    'reply_markup': {
      'inline_keyboard': inlineKeyboard
          .map((row) => row.map((b) => b.toJson()).toList())
          .toList(),
    },
  };
}

/// Service that parses Telegram chat commands and dispatches localized Mini App deep link replies.
class TelegramBotCommandHandler {
  static const String miniAppBaseUrl = 'https://t.me/around_tashkent_bot/app';
  static const String webAppBaseUrl = 'https://around.tashkent.app';

  /// Processes an incoming raw Telegram message text and generates the bot reply.
  TelegramBotReply handleMessage({
    required String messageText,
    String? fromUsername,
    String languageCode = 'en',
  }) {
    final trimmed = messageText.trim();
    final parts = trimmed.split(RegExp(r'\s+'));
    final commandStr = parts.isNotEmpty ? parts[0] : '';
    final argument = parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';

    final command = TelegramBotCommand.fromString(commandStr);
    final lang = languageCode.toLowerCase();

    switch (command) {
      case TelegramBotCommand.start:
        return _handleStart(argument, fromUsername, lang);

      case TelegramBotCommand.passport:
        return _handlePassport(argument, fromUsername, lang);

      case TelegramBotCommand.trophies:
        return _handleTrophies(lang);

      case TelegramBotCommand.routes:
        return _handleRoutes(lang);

      case TelegramBotCommand.help:
        return _handleHelp(lang);

      case TelegramBotCommand.unknown:
        return _handleUnknown(commandStr, lang);
    }
  }

  TelegramBotReply _handleStart(String? payload, String? username, String lang) {
    final cleanPayload = (payload ?? '').trim();
    final hasRoute = cleanPayload.startsWith('route_');
    final hasPostcard = cleanPayload.startsWith('postcard_');

    String text;
    String buttonText;
    String launchUrl;

    if (hasRoute) {
      if (lang.startsWith('uz')) {
        text = '🧭 *Around Tashkent: Saralangan Marshrut*\n\nDo\'stingiz siz bilan maxsus marshrutni ulashdi. Toshkentning eng yaxshi joylarini birga kashf eting!';
        buttonText = '🚶 Marshrutni Ochish';
      } else if (lang.startsWith('ru')) {
        text = '🧭 *Around Tashkent: Кураторский Маршрут*\n\nВаш друг поделился авторским маршрутом по Ташкенту. Исследуйте лучшие заведения города!';
        buttonText = '🚶 Открыть Маршрут';
      } else {
        text = '🧭 *Around Tashkent: Curated Route*\n\nA friend shared a handpicked discovery trail with you. Explore the best spots in Tashkent!';
        buttonText = '🚶 Open Curated Route';
      }
      launchUrl = '$miniAppBaseUrl?startapp=$cleanPayload';
    } else if (hasPostcard) {
      if (lang.startsWith('uz')) {
        text = '💌 *Madaniy Otkritka & Chek*\n\nSizga Tashkent Taste Postcard yuborildi. Kurator taassurotlarini ko\'ring!';
        buttonText = '💌 Otkritkani Ko\'rish';
      } else if (lang.startsWith('ru')) {
        text = '💌 *Культурная Открытка и Чек*\n\nВам прислали Tashkent Taste Postcard. Посмотрите впечатления куратора!';
        buttonText = '💌 Посмотреть Открытку';
      } else {
        text = '💌 *Cultural Receipt Postcard*\n\nYou received a Tashkent Taste Postcard. Discover the curator\'s experience!';
        buttonText = '💌 View Postcard';
      }
      launchUrl = '$miniAppBaseUrl?startapp=$cleanPayload';
    } else {
      final greet = username != null && username.isNotEmpty ? ', @$username' : '';
      if (lang.startsWith('uz')) {
        text = '👋 *Xush kelibsiz$greet!* Around — Toshkentning do\'stlar orqali joylarni kashf etish ijtimoiy xaritasi.\n\n🏆 Oylik mavsumlarda qatnashing\n🧭 Saralangan marshrutlarni yuring\n👑 Tuman tojlarini yuting!';
        buttonText = '🚀 Around Mini App-ni Ochish';
      } else if (lang.startsWith('ru')) {
        text = '👋 *Добро пожаловать$greet!* Around — городская социальная сеть открытий Ташкента.\n\n🏆 Участвуйте в сезонах\n🧭 Проходите кураторские маршруты\n👑 Завоюйте короны районов!';
        buttonText = '🚀 Запустить Mini App';
      } else {
        text = '👋 *Welcome$greet!* Around is Tashkent\'s places-first social discovery platform.\n\n🏆 Compete in monthly curator seasons\n🧭 Walk curated district routes\n👑 Win district crowns & trophies!';
        buttonText = '🚀 Launch Mini App';
      }
      launchUrl = miniAppBaseUrl;
    }

    return TelegramBotReply(
      text: text,
      command: TelegramBotCommand.start,
      inlineKeyboard: [
        [TelegramInlineButton(text: buttonText, webAppUrl: launchUrl)],
        [
          TelegramInlineButton(
            text: lang.startsWith('uz') ? '🌐 Veb Ilova' : (lang.startsWith('ru') ? '🌐 Веб-Версия' : '🌐 Web Companion'),
            url: webAppBaseUrl,
          ),
        ],
      ],
    );
  }

  TelegramBotReply _handlePassport(String usernameArg, String? fromUsername, String lang) {
    final target = usernameArg.isNotEmpty
        ? usernameArg.replaceAll('@', '').trim()
        : (fromUsername?.replaceAll('@', '').trim() ?? 'you');

    String text;
    String buttonText;

    if (lang.startsWith('uz')) {
      text = '📜 *@$target Ta\'m Pasporti*\n\nTumanlar qamrovi, yutilgan kuboklar, tuman tojlari va saralangan joylar.';
      buttonText = '📜 Pasportni Ko\'rish';
    } else if (lang.startsWith('ru')) {
      text = '📜 *Паспорт Вкуса @$target*\n\nОхват районов, сезонные трофеи, короны районов и проверенные места.';
      buttonText = '📜 Открыть Паспорт';
    } else {
      text = '📜 *@$target\'s Taste Passport*\n\nDistrict coverage, seasonal trophies, crowns, and verified local recommendations.';
      buttonText = '📜 View Taste Passport';
    }

    final startappParam = target == 'you' ? 'passport' : 'passport_$target';

    return TelegramBotReply(
      text: text,
      command: TelegramBotCommand.passport,
      inlineKeyboard: [
        [TelegramInlineButton(text: buttonText, webAppUrl: '$miniAppBaseUrl?startapp=$startappParam')],
      ],
    );
  }

  TelegramBotReply _handleTrophies(String lang) {
    String text;
    String buttonText;

    if (lang.startsWith('uz')) {
      text = '🏆 *Around Mavsumiy Kuboklar & Shon-Sharaf Zali*\n\nHar oy Toshkentning 12 tumanida kuratorlar musobaqalashadi. Eng yaxshilar oltin, kumush kuboklar va tuman tojlarini qo\'lga kiritadi!';
      buttonText = '🏆 Kuboklar Devorini Ko\'rish';
    } else if (lang.startsWith('ru')) {
      text = '🏆 *Сезонные Трофеи и Зал Славы Around*\n\nКаждый месяц кураторы соревнуются в 12 районах Ташкента. Топ-исследователи получают золотые кубки и короны районов!';
      buttonText = '🏆 Открыть Стену Трофеев';
    } else {
      text = '🏆 *Around Seasonal Trophies & Hall of Fame*\n\nEvery month curators explore Tashkent\'s 12 districts. Top explorers claim gold trophies and district crowns!';
      buttonText = '🏆 View Trophy Wall';
    }

    return TelegramBotReply(
      text: text,
      command: TelegramBotCommand.trophies,
      inlineKeyboard: [
        [TelegramInlineButton(text: buttonText, webAppUrl: '$miniAppBaseUrl?startapp=trophies')],
      ],
    );
  }

  TelegramBotReply _handleRoutes(String lang) {
    String text;
    String buttonText;

    if (lang.startsWith('uz')) {
      text = '🧭 *Toshkent Saralangan Marshrutlari*\n\n• Mirabad Specialty Coffee Crawl\n• Chorsu & Eski Shahar Hunarmandchilik Sayri\n• Brodvey & Amir Temur Kechki Yurishi\n\nAudio-gid va audio teginish bilan qulay sayr qiling!';
      buttonText = '🧭 Marshrutlarni Ko\'rish';
    } else if (lang.startsWith('ru')) {
      text = '🧭 *Кураторские Маршруты Ташкента*\n\n• Кофейная миля Мирабада\n• Ремесленный маршрут Старого Города (Чорсу)\n• Вечерняя прогулка по Бродвею и Скверу\n\nС аудио-гидом и звуковыми метками!';
      buttonText = '🧭 Смотреть Маршруты';
    } else {
      text = '🧭 *Tashkent Curated Discovery Trails*\n\n• Mirabad Specialty Coffee Crawl\n• Chorsu & Old City Artisan Walk\n• Broadway & Amir Temur Evening Stroll\n\nEquipped with audio guide commentary and rhythmic waypoints!';
      buttonText = '🧭 Explore Discovery Trails';
    }

    return TelegramBotReply(
      text: text,
      command: TelegramBotCommand.routes,
      inlineKeyboard: [
        [TelegramInlineButton(text: buttonText, webAppUrl: '$miniAppBaseUrl?startapp=routes')],
      ],
    );
  }

  TelegramBotReply _handleHelp(String lang) {
    String text;
    if (lang.startsWith('uz')) {
      text = '🤖 *Around Toshkent Boti Buyruqlari:*\n\n/start — Ilovani ishga tushirish\n/passport — O\'z ta\'m pasportingizni ko\'rish\n/passport [username] — Boshqa kurator pasporti\n/trophies — Oylik mavsumiy kuboklar va shon-sharaf zali\n/routes — Saralangan shahar marshrutlari\n/help — Ushbu yordam xabari';
    } else if (lang.startsWith('ru')) {
      text = '🤖 *Команды бота Around Ташкент:*\n\n/start — Запустить приложение\n/passport — Ваш паспорт вкуса\n/passport [username] — Паспорт другого куратора\n/trophies — Сезонные трофеи и Зал Славы\n/routes — Кураторские маршруты по городу\n/help — Справка по командам';
    } else {
      text = '🤖 *Around Tashkent Bot Commands:*\n\n/start — Launch the Mini App\n/passport — Your taste passport\n/passport [username] — View a curator\'s passport\n/trophies — Monthly trophy wall & Hall of Fame\n/routes — Curated city discovery trails\n/help — List available commands';
    }

    return TelegramBotReply(
      text: text,
      command: TelegramBotCommand.help,
      inlineKeyboard: const [
        [TelegramInlineButton(text: '🚀 Open Mini App', webAppUrl: miniAppBaseUrl)],
      ],
    );
  }

  TelegramBotReply _handleUnknown(String commandStr, String lang) {
    String text;
    if (lang.startsWith('uz')) {
      text = '❓ Noma\'lum buyruq: `$commandStr`.\n\nMavjud buyruqlarni ko\'rish uchun /help ni yuboring.';
    } else if (lang.startsWith('ru')) {
      text = '❓ Неизвестная команда: `$commandStr`.\n\nОтправьте /help для списка доступных команд.';
    } else {
      text = '❓ Unknown command: `$commandStr`.\n\nSend /help to view available commands.';
    }

    return TelegramBotReply(
      text: text,
      command: TelegramBotCommand.unknown,
      inlineKeyboard: const [
        [TelegramInlineButton(text: '🚀 Open Mini App', webAppUrl: miniAppBaseUrl)],
      ],
    );
  }
}

final telegramBotCommandHandlerProvider = Provider<TelegramBotCommandHandler>((ref) {
  return TelegramBotCommandHandler();
});
