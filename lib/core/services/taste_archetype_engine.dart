import '../../data/models/place_model.dart';

/// The 5 canonical taste dimensions of Tashkent city discovery (`P15-02`).
enum TasteDimension {
  specialtyCoffee('Specialty Coffee', '☕'),
  nationalDining('National Dining', '🍲'),
  artsAndCulture('Arts & Culture', '🏛️'),
  nightlifeAndSocial('Nightlife & Social', '🍷'),
  parksAndGreen('Parks & Greenery', '🌿');

  final String label;
  final String icon;

  const TasteDimension(this.label, this.icon);
}

/// Profile containing the multi-axis distribution and calculated explorer archetype.
class TasteRadarProfile {
  final String archetypeTitleEn;
  final String archetypeTitleRu;
  final String archetypeTitleUz;
  final String archetypeIcon;
  final String descriptionEn;
  final String descriptionRu;
  final String descriptionUz;
  final Map<TasteDimension, double> dimensionWeights;
  final double diversityScore;
  final int totalVenuesAnalyzed;

  const TasteRadarProfile({
    required this.archetypeTitleEn,
    required this.archetypeTitleRu,
    required this.archetypeTitleUz,
    required this.archetypeIcon,
    required this.descriptionEn,
    required this.descriptionRu,
    required this.descriptionUz,
    required this.dimensionWeights,
    required this.diversityScore,
    required this.totalVenuesAnalyzed,
  });

  String getArchetypeTitle(String langCode) {
    switch (langCode.toLowerCase().trim()) {
      case 'uz':
        return archetypeTitleUz;
      case 'ru':
        return archetypeTitleRu;
      case 'en':
      default:
        return archetypeTitleEn;
    }
  }

  String getDescription(String langCode) {
    switch (langCode.toLowerCase().trim()) {
      case 'uz':
        return descriptionUz;
      case 'ru':
        return descriptionRu;
      case 'en':
      default:
        return descriptionEn;
    }
  }
}

/// Engine that calculates category distribution and classifies user discovery archetypes (`P15-02`).
class TasteArchetypeEngine {
  /// Analyzes a collection of places and produces a structured TasteRadarProfile.
  static TasteRadarProfile analyze(List<PlaceModel> places) {
    final counts = <TasteDimension, int>{
      TasteDimension.specialtyCoffee: 0,
      TasteDimension.nationalDining: 0,
      TasteDimension.artsAndCulture: 0,
      TasteDimension.nightlifeAndSocial: 0,
      TasteDimension.parksAndGreen: 0,
    };

    if (places.isEmpty) {
      return const TasteRadarProfile(
        archetypeTitleEn: 'Curious Newcomer',
        archetypeTitleRu: 'Новый Исследователь',
        archetypeTitleUz: 'Yangi Sayyoh',
        archetypeIcon: '✨',
        descriptionEn: 'Start dropping and saving your favorite Tashkent spots to reveal your taste radar.',
        descriptionRu: 'Делитесь дропами и сохраняйте любимые места, чтобы раскрыть свой радар вкуса.',
        descriptionUz: 'Toshkentdagi sevimli maskanlaringizni saqlang va did radaringizni kashf qiling.',
        dimensionWeights: {
          TasteDimension.specialtyCoffee: 0.2,
          TasteDimension.nationalDining: 0.2,
          TasteDimension.artsAndCulture: 0.2,
          TasteDimension.nightlifeAndSocial: 0.2,
          TasteDimension.parksAndGreen: 0.2,
        },
        diversityScore: 0.0,
        totalVenuesAnalyzed: 0,
      );
    }

    for (final p in places) {
      final combined = '${p.category} ${p.tags.join(' ')} ${p.name} ${p.description}'.toLowerCase();

      if (combined.contains('coffee') || combined.contains('bakery') || combined.contains('café') || combined.contains('dessert') || combined.contains('croissant')) {
        counts[TasteDimension.specialtyCoffee] = counts[TasteDimension.specialtyCoffee]! + 1;
      } else if (combined.contains('plov') || combined.contains('osh') || combined.contains('choyxona') || combined.contains('national') || combined.contains('shashlik') || combined.contains('somsa')) {
        counts[TasteDimension.nationalDining] = counts[TasteDimension.nationalDining]! + 1;
      } else if (combined.contains('wine') || combined.contains('bar') || combined.contains('cocktail') || combined.contains('night') || combined.contains('bistro') || combined.contains('pub')) {
        counts[TasteDimension.nightlifeAndSocial] = counts[TasteDimension.nightlifeAndSocial]! + 1;
      } else if (combined.contains('art') || combined.contains('gallery') || combined.contains('museum') || combined.contains('theater') || combined.contains('book')) {
        counts[TasteDimension.artsAndCulture] = counts[TasteDimension.artsAndCulture]! + 1;
      } else if (combined.contains('park') || combined.contains('garden') || combined.contains('walk') || combined.contains('green')) {
        counts[TasteDimension.parksAndGreen] = counts[TasteDimension.parksAndGreen]! + 1;
      } else {
        // Default bucket for general dining
        counts[TasteDimension.nationalDining] = counts[TasteDimension.nationalDining]! + 1;
      }
    }

    final totalCount = places.length;
    final weights = <TasteDimension, double>{};
    int nonZeroDimensions = 0;

    TasteDimension dominant = TasteDimension.specialtyCoffee;
    int maxCount = -1;

    for (final entry in counts.entries) {
      final weight = entry.value / totalCount;
      weights[entry.key] = weight;
      if (entry.value > 0) nonZeroDimensions++;
      if (entry.value > maxCount) {
        maxCount = entry.value;
        dominant = entry.key;
      }
    }

    final diversityScore = nonZeroDimensions / TasteDimension.values.length;
    final dominantShare = maxCount / totalCount;

    String titleEn;
    String titleRu;
    String titleUz;
    String icon;
    String descEn;
    String descRu;
    String descUz;

    if (diversityScore >= 0.6 && dominantShare < 0.45) {
      titleEn = 'All-Around Tashkent Explorer';
      titleRu = 'Универсальный Ташкентец';
      titleUz = 'Toshkent Sayyohi';
      icon = '🧭';
      descEn = 'Balanced taste across coffee, heritage, evening gatherings, and city parks.';
      descRu = 'Сбалансированный вкус: кофе, история, вечерний отдых и прогулки по паркам.';
      descUz = "Qahva, milliy meros, oqshom suhbatlari va shahar bog'lari bo'yicha uyg'un did.";
    } else {
      switch (dominant) {
        case TasteDimension.specialtyCoffee:
          titleEn = 'Specialty Connoisseur';
          titleRu = 'Кофейный Знаток';
          titleUz = 'Qahva Bilagdoni';
          icon = '☕';
          descEn = 'Frequently drawn to third-wave coffee roasters, quiet morning light, and artisan bakeries.';
          descRu = 'Ценитель спешелти-кофе, утренней тишины и ремесленной выпечки в Ташкенте.';
          descUz = "Yangi qovurilgan qahva, ertalabki sokinlik va shinam novvoyxonalar ixlosmandi.";
          break;
        case TasteDimension.nationalDining:
          titleEn = 'Old City Gourmet';
          titleRu = 'Гурман Старого Города';
          titleUz = 'Milliy Taomlar Ustasi';
          icon = '🍲';
          descEn = 'Passionate seeker of authentic plov centers, family teahouses, and legendary wood-fired somsa.';
          descRu = 'Искатель аутентичного плова, семейных чайхан и легендарной тандырной самсы.';
          descUz = "Haqiqiy toshkentcha osh markazlari, oilaviy choyxonalar va tansiq taomlar shaydosi.";
          break;
        case TasteDimension.artsAndCulture:
          titleEn = 'Urban Culturist';
          titleRu = 'Культурный Эстет';
          titleUz = 'Shahar Madaniyatshunosi';
          icon = '🏛️';
          descEn = 'Drawn to gallery openings, Soviet modernist architecture, and independent Tashkent bookstores.';
          descRu = 'Вдохновляется выставками, советским модернизмом и независимыми книжными.';
          descUz = "Ko'rgazmalar, me'moriy yodgorliklar va mustaqil kitob do'konlari ixlosmandi.";
          break;
        case TasteDimension.nightlifeAndSocial:
          titleEn = 'Evening Epicurean';
          titleRu = 'Вечерний Эпикуреец';
          titleUz = 'Oqshom Sayrchisi';
          icon = '🍷';
          descEn = 'Thrives in candlelit wine bistros, vinyl listening bars, and lively weekend terraces.';
          descRu = 'Предпочитает уютные винные бистро, бары с винилом и оживленные летние террасы.';
          descUz = "Shinam vino bistrolari, sokin musiqa barlari va do'stona oqshom davralari sevgisi.";
          break;
        case TasteDimension.parksAndGreen:
          titleEn = 'Green Haven Wanderer';
          titleRu = 'Искатель Зеленых Оазисов';
          titleUz = "Yashil Voha Sayyohi";
          icon = '🌿';
          descEn = 'Finds solace in shaded botanical gardens, canal walkways, and breezy Tashkent parks.';
          descRu = 'Любит тенистые ботанические сады, прогулки вдоль каналов и зеленые парки столицы.';
          descUz = "Soyali botanika bog'lari, anhor bo'yi sayrlari va shahar bog'lari oshig'i.";
          break;
      }
    }

    return TasteRadarProfile(
      archetypeTitleEn: titleEn,
      archetypeTitleRu: titleRu,
      archetypeTitleUz: titleUz,
      archetypeIcon: icon,
      descriptionEn: descEn,
      descriptionRu: descRu,
      descriptionUz: descUz,
      dimensionWeights: weights,
      diversityScore: diversityScore,
      totalVenuesAnalyzed: totalCount,
    );
  }
}
