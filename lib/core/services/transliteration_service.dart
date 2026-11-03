/// Transliteration & Multilingual Search Normalizer for Uzbekistan (`P14-02`).
/// Bridges Uzbek Cyrillic, Uzbek Latin, Russian, and English spellings for Tashkent discovery.
class TransliterationService {
  static const Map<String, String> _cyrillicToLatinMap = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd',
    'е': 'e', 'ё': 'yo', 'ж': 'j', 'з': 'z', 'и': 'i',
    'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n',
    'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't',
    'у': 'u', 'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch',
    'ш': 'sh', 'щ': 'sh', 'ъ': "'", 'ы': 'i', 'ь': '',
    'э': 'e', 'ю': 'yu', 'я': 'ya',
    'ў': "o'", 'ғ': "g'", 'қ': 'q', 'ҳ': 'h',
    'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D',
    'Е': 'E', 'Ё': 'Yo', 'Ж': 'J', 'З': 'Z', 'И': 'I',
    'Й': 'Y', 'К': 'K', 'Л': 'L', 'М': 'M', 'Н': 'N',
    'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T',
    'У': 'U', 'Ф': 'F', 'Х': 'X', 'Ц': 'Ts', 'Ч': 'Ch',
    'Ш': 'Sh', 'Щ': 'Sh', 'Ъ': "'", 'Ы': 'I', 'Ь': '',
    'Э': 'E', 'Ю': 'Yu', 'Я': 'Ya',
    'Ў': "O'", 'Ғ': "G'", 'Қ': 'Q', 'Ҳ': 'H',
  };

  /// Common category and keyword synonyms across Russian, Uzbek, and English
  static const Map<String, List<String>> _crossLanguageKeywords = {
    'coffee': ['кофе', 'кофейня', 'кафе', 'qahva', 'qahvaxona', 'specialty coffee', 'espresso', 'cappuccino'],
    'bakery': ['пекарня', 'выпечка', 'круассан', 'nonvoyxona', 'non', 'croissant', 'bread', 'pastry'],
    'plov': ['плов', 'ош', 'osh', 'oshpaz', 'samarkand plov', 'tashkent plov'],
    'wine': ['вино', 'винный бар', 'enoteca', 'tapas', 'vino', 'mayxona'],
    'tea': ['чай', 'чайхана', 'чой', 'чойхона', 'choyxona', 'choy'],
    'books': ['книги', 'книжный', 'библиотека', 'kitob', 'kitobxon', 'kutubxona', 'read'],
    'art': ['искусство', 'галерея', 'музей', 'sanat', 'galereya', 'muzey', 'exhibition'],
    'park': ['парк', 'сад', 'сквер', 'sayilgoh', 'bog', 'green'],
    'restaurant': ['ресторан', 'обед', 'ужин', 'taom', 'oshxona', 'dining'],
    'mirabad': ['миробод', 'миробад', 'mirobod', 'mirabad', 'миробод тумани', 'mirabad district'],
    'yakkasaray': ['яккасарой', 'яккасарай', 'yakkasaroy', 'yakkasaray'],
    'yunusabad': ['юнусобод', 'юнусабад', 'yunusobod', 'yunusabad'],
    'shaykhontohur': ['шайхонтоҳур', 'шайхантахур', 'shayxontohur', 'shaykhontohur', 'shayhantahur'],
    'central tashkent': ['марказ', 'центр', 'shahar markazi', 'tashkent center', 'markaz'],
  };

  /// Converts Uzbek/Russian Cyrillic string to normalized Latin representation.
  static String cyrillicToLatin(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      buffer.write(_cyrillicToLatinMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// Normalizes apostrophes and special modifier characters across keyboards (`o'`, `o’`, `oʻ`, `oʼ`).
  static String normalizeApostrophes(String input) {
    return input.replaceAll(RegExp(r"['’`ʻʼ]"), "'");
  }

  /// Standardizes query string: lowercases, trims, normalizes apostrophes, and transliterates Cyrillic.
  static String normalizeQuery(String query) {
    final lower = query.trim().toLowerCase();
    final withStandardApostrophes = normalizeApostrophes(lower);
    return cyrillicToLatin(withStandardApostrophes);
  }

  /// Returns canonical keyword expansions for a query across Russian, Uzbek, and English.
  static Set<String> expandSearchTerms(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return const {};

    final normalized = normalizeQuery(clean);
    final terms = <String>{normalized, clean};

    // Add individual word tokens
    final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.length >= 2).toSet();
    terms.addAll(tokens);

    // Only expand synonyms when a whole token or the whole clean query matches
    for (final entry in _crossLanguageKeywords.entries) {
      final categoryKey = entry.key;
      final synonyms = entry.value;

      final isExactMatch = tokens.contains(categoryKey) ||
          clean == categoryKey ||
          synonyms.any((s) {
            final sLower = s.toLowerCase();
            final sNorm = normalizeQuery(sLower);
            return tokens.contains(sNorm) || tokens.contains(sLower) || clean == sLower || clean == sNorm;
          });

      if (isExactMatch) {
        terms.add(categoryKey);
        for (final s in synonyms) {
          final sNorm = normalizeQuery(s);
          if (sNorm.length >= 3) {
            terms.add(sNorm);
          }
        }
      }
    }

    return terms;
  }
}
