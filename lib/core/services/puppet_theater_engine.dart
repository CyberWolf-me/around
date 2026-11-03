import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Traditional Uzbek puppetry formats.
enum PuppetType {
  chodirJamol(
    id: 'chodir_jamol',
    nameEn: 'Chodir Jamol (Glove Puppet)',
    nameUz: 'Chodir Jamol (Qo\'lqop qo\'g\'irchoq)',
    nameRu: 'Чодир Жамол (Перчаточная кукла)',
    description: 'Dynamic glove puppet theater performing satirical folk tales and comedic sketches.',
  ),
  chodirXayol(
    id: 'chodir_xayol',
    nameEn: 'Chodir Xayol (String Marionette)',
    nameUz: 'Chodir Xayol (Simli marionetka)',
    nameRu: 'Чодир Хаёл (Нитяная марионетка)',
    description: 'Intricate multi-string marionettes suspended from wooden cross braces, performing epic legends.',
  ),
  soyaQogirchoq(
    id: 'soya_qogirchoq',
    nameEn: 'Soya Qo\'g\'irchoq (Shadow Puppet)',
    nameUz: 'Soya qo\'g\'irchoq (Soyalar teatri)',
    nameRu: 'Соя кугирчок (Театр теней)',
    description: 'Perforated parchment leather silhouettes projected onto illuminated silk screens.',
  );

  final String id;
  final String nameEn;
  final String nameUz;
  final String nameRu;
  final String description;

  const PuppetType({
    required this.id,
    required this.nameEn,
    required this.nameUz,
    required this.nameRu,
    required this.description,
  });

  String localizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'uz':
        return nameUz;
      case 'ru':
        return nameRu;
      case 'en':
      default:
        return nameEn;
    }
  }

  static PuppetType fromId(String id) {
    return PuppetType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => PuppetType.chodirXayol,
    );
  }
}

/// Traditional wood varieties carved for puppet bodies and joint articulation.
enum CarvingWood {
  chinor(
    id: 'chinor',
    nameEn: 'Chinor (Oriental Plane Tree)',
    nameUz: 'Chinor yog\'ochi',
    nameRu: 'Чинара (Восточный платан)',
    hardnessMohs: 3.5,
    description: 'Fine-grained, non-splintering plane tree wood favored for expressive facial carvings.',
  ),
  walnut(
    id: 'walnut',
    nameEn: 'Yong\'oq (Mountain Walnut)',
    nameUz: 'Yong\'oq yog\'ochi',
    nameRu: 'Горный грецкий орех',
    hardnessMohs: 4.0,
    description: 'Dense dark timber providing lustrous polish for royal regalia and headdresses.',
  ),
  apricot(
    id: 'apricot',
    nameEn: 'O\'rik (Wild Apricot)',
    nameUz: 'O\'rik yog\'ochi',
    nameRu: 'Дикий абрикос',
    hardnessMohs: 4.5,
    description: 'Extremely tough, resonant timber carved for miniature joint pins and string pulleys.',
  );

  final String id;
  final String nameEn;
  final String nameUz;
  final String nameRu;
  final double hardnessMohs;
  final String description;

  const CarvingWood({
    required this.id,
    required this.nameEn,
    required this.nameUz,
    required this.nameRu,
    required this.hardnessMohs,
    required this.description,
  });

  String localizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'uz':
        return nameUz;
      case 'ru':
        return nameRu;
      case 'en':
      default:
        return nameEn;
    }
  }

  static CarvingWood fromId(String id) {
    return CarvingWood.values.firstWhere(
      (w) => w.id == id,
      orElse: () => CarvingWood.chinor,
    );
  }
}

/// Marionette or Glove puppet figure carved by Tashkent masters.
class MarionetteFigure {
  final String id;
  final String nameEn;
  final String nameUz;
  final String nameRu;
  final PuppetType puppetType;
  final CarvingWood carvingWood;
  final int stringsCount;
  final String characterRole;
  final String costumeFabric;

  const MarionetteFigure({
    required this.id,
    required this.nameEn,
    required this.nameUz,
    required this.nameRu,
    required this.puppetType,
    required this.carvingWood,
    required this.stringsCount,
    required this.characterRole,
    required this.costumeFabric,
  });

  String localizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'uz':
        return nameUz;
      case 'ru':
        return nameRu;
      case 'en':
      default:
        return nameEn;
    }
  }
}

/// Performance show playing at a Tashkent puppet stage.
class PuppetPerformance {
  final String id;
  final String titleEn;
  final String titleUz;
  final String titleRu;
  final PuppetType puppetType;
  final int durationMinutes;
  final int ticketPriceUzs;
  final int minimumAge;
  final String scheduleTime;
  final String synopsis;

  const PuppetPerformance({
    required this.id,
    required this.titleEn,
    required this.titleUz,
    required this.titleRu,
    required this.puppetType,
    required this.durationMinutes,
    required this.ticketPriceUzs,
    required this.minimumAge,
    required this.scheduleTime,
    required this.synopsis,
  });

  String localizedTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'uz':
        return titleUz;
      case 'ru':
        return titleRu;
      case 'en':
      default:
        return titleEn;
    }
  }
}

/// Traditional puppet theater venue or master woodcarver atelier.
class PuppetTheaterStage {
  final String id;
  final String name;
  final String district;
  final String chiefMaster;
  final int foundedYear;
  final int availableSeats;
  final double latitude;
  final double longitude;
  final List<PuppetPerformance> repertoire;
  final List<MarionetteFigure> signatureFigures;

  const PuppetTheaterStage({
    required this.id,
    required this.name,
    required this.district,
    required this.chiefMaster,
    required this.foundedYear,
    required this.availableSeats,
    required this.latitude,
    required this.longitude,
    required this.repertoire,
    required this.signatureFigures,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'district': district,
        'chief_master': chiefMaster,
        'founded_year': foundedYear,
        'available_seats': availableSeats,
        'latitude': latitude,
        'longitude': longitude,
        'repertoire_count': repertoire.length,
        'figures_count': signatureFigures.length,
      };
}

/// Record of a reserved ticket or masterclass seat.
class PuppetTicketReservation {
  final String stageId;
  final String performanceId;
  final int seatsCount;
  final DateTime reservedAt;
  final int xpEarned;
  final String status;

  const PuppetTicketReservation({
    required this.stageId,
    required this.performanceId,
    required this.seatsCount,
    required this.reservedAt,
    this.xpEarned = 35,
    this.status = 'confirmed',
  });
}

/// Pure Dart Domain Service Engine for Tashkent Puppet Theater & Marionette Craft.
class PuppetTheaterEngine {
  final List<PuppetTheaterStage> stages;

  PuppetTheaterEngine({List<PuppetTheaterStage>? stages})
      : stages = stages ?? defaultStages;

  static final List<PuppetTheaterStage> defaultStages = [
    const PuppetTheaterStage(
      id: 'theater-state-puppet-kosmonavtlar',
      name: 'Uzbekistan State Puppet Theater',
      district: 'Yakkasaray Kosmonavtlar',
      chiefMaster: 'Usto Mansur Qo\'g\'irchoqsoz',
      foundedYear: 1939,
      availableSeats: 48,
      latitude: 41.3052,
      longitude: 69.2618,
      repertoire: [
        PuppetPerformance(
          id: 'show-polvon-kachal-wedding',
          titleEn: 'The Hilarious Wedding of Polvon Kachal',
          titleUz: 'Polvon Kachalning To\'yi',
          titleRu: 'Свадьба Палвана Качала',
          puppetType: PuppetType.chodirJamol,
          durationMinutes: 50,
          ticketPriceUzs: 35000,
          minimumAge: 4,
          scheduleTime: '11:00 AM & 3:00 PM',
          synopsis: 'Classic Uzbek folk comedy starring the irreverent glove puppet hero Polvon Kachal outwitting greedy merchants.',
        ),
        PuppetPerformance(
          id: 'show-simurgh-legend',
          titleEn: 'The Flight of the Sacred Simurgh',
          titleUz: 'Semurg\' Qushining Parvozi',
          titleRu: 'Полет Священного Семурга',
          puppetType: PuppetType.chodirXayol,
          durationMinutes: 65,
          ticketPriceUzs: 50000,
          minimumAge: 6,
          scheduleTime: '6:30 PM',
          synopsis: 'Spectacular multi-string marionette epic following young Farhod across mythological peaks guided by the golden Simurgh.',
        ),
      ],
      signatureFigures: [
        MarionetteFigure(
          id: 'figure-polvon-kachal',
          nameEn: 'Polvon Kachal (The Folk Wrestler)',
          nameUz: 'Polvon Kachal',
          nameRu: 'Палван Качал',
          puppetType: PuppetType.chodirJamol,
          carvingWood: CarvingWood.chinor,
          stringsCount: 0,
          characterRole: 'Protagonist Trickster',
          costumeFabric: 'Striped Bekasab Silk Chapan',
        ),
        MarionetteFigure(
          id: 'figure-farhod-hero',
          nameEn: 'Farhod the Stonecutter',
          nameUz: 'Toshkesuvchi Farhod',
          nameRu: 'Фархад Каменотёс',
          puppetType: PuppetType.chodirXayol,
          carvingWood: CarvingWood.walnut,
          stringsCount: 10,
          characterRole: 'Epic Hero',
          costumeFabric: 'Adras Ikat Tunic with Silver Belt',
        ),
      ],
    ),
    const PuppetTheaterStage(
      id: 'atelier-old-city-chodir',
      name: 'Old City Chodir Jamol Master Atelier',
      district: 'Shaykhontohur Chorsu',
      chiefMaster: 'Usto Ikrom Usta-Qo\'g\'irchoq',
      foundedYear: 1978,
      availableSeats: 16,
      latitude: 41.3268,
      longitude: 69.2372,
      repertoire: [
        PuppetPerformance(
          id: 'show-nasriddin-donkey',
          titleEn: 'Afandi and the Wise Donkey',
          titleUz: 'Afandi va Dono Eshak',
          titleRu: 'Афанди и Мудрый Осёл',
          puppetType: PuppetType.chodirJamol,
          durationMinutes: 45,
          ticketPriceUzs: 40000,
          minimumAge: 5,
          scheduleTime: '2:00 PM',
          synopsis: 'Humorous philosophical miniature with Nasriddin Afandi negotiating the Chorsu bazaar crowd.',
        ),
      ],
      signatureFigures: [
        MarionetteFigure(
          id: 'figure-afandi',
          nameEn: 'Nasriddin Afandi',
          nameUz: 'Xo\'ja Nasriddin Afandi',
          nameRu: 'Ходжа Насреддин Афанди',
          puppetType: PuppetType.chodirJamol,
          carvingWood: CarvingWood.apricot,
          stringsCount: 0,
          characterRole: 'Philosopher Sage',
          costumeFabric: 'White Cotton Turban and Blue Velvet Robe',
        ),
      ],
    ),
    const PuppetTheaterStage(
      id: 'studio-chilonzor-marionette',
      name: 'Chilonzor Silk String Marionette Studio',
      district: 'Chilonzor Quarter 7',
      chiefMaster: 'Usto Dilshod Marionetkasoz',
      foundedYear: 1995,
      availableSeats: 24,
      latitude: 41.2842,
      longitude: 69.2155,
      repertoire: [
        PuppetPerformance(
          id: 'show-tahir-zuhra',
          titleEn: 'Tahir and Zuhra: A Musical Tapestry',
          titleUz: 'Tohir va Zuhra Marionetka Tomoshasi',
          titleRu: 'Тахир и Зухра: Нитяная Сказка',
          puppetType: PuppetType.chodirXayol,
          durationMinutes: 60,
          ticketPriceUzs: 45000,
          minimumAge: 7,
          scheduleTime: '5:00 PM',
          synopsis: 'Tender romance told with 12-string articulated marionettes dancing to live dutar and chang acoustics.',
        ),
      ],
      signatureFigures: [
        MarionetteFigure(
          id: 'figure-zuhra-princess',
          nameEn: 'Princess Zuhra',
          nameUz: 'Malika Zuhra',
          nameRu: 'Принцесса Зухра',
          puppetType: PuppetType.chodirXayol,
          carvingWood: CarvingWood.chinor,
          stringsCount: 12,
          characterRole: 'Heroine',
          costumeFabric: 'Gold Zardozi Embroidered Silk Satin',
        ),
      ],
    ),
  ];

  /// Locates stage venue by ID.
  PuppetTheaterStage? findStageById(String id) {
    try {
      return stages.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Filters stages by puppetry format.
  List<PuppetTheaterStage> filterByPuppetType(PuppetType type) {
    return stages.where((s) {
      return s.repertoire.any((p) => p.puppetType == type) ||
          s.signatureFigures.any((f) => f.puppetType == type);
    }).toList();
  }

  /// Calculates marionette string tension ratio (0.0 to 1.0) based on controller tilt angle.
  double calculateStringTension({
    required int stringIndex,
    required double tiltAngleDegrees,
  }) {
    final clampedAngle = tiltAngleDegrees.clamp(-45.0, 45.0);
    // Base tension is normalized at 0.5; controller tilt modulates tension based on string index parity
    final bias = (stringIndex % 2 == 0 ? 1 : -1) * (clampedAngle / 90.0);
    return (0.5 + bias).clamp(0.0, 1.0);
  }

  /// Reserves tickets and awards +35 Explorer XP.
  PuppetTicketReservation reserveTickets({
    required String stageId,
    required String performanceId,
    int seatsCount = 1,
  }) {
    return PuppetTicketReservation(
      stageId: stageId,
      performanceId: performanceId,
      seatsCount: seatsCount,
      reservedAt: DateTime.now(),
      xpEarned: 35,
      status: 'confirmed',
    );
  }
}

/// Riverpod Provider for PuppetTheaterEngine.
final puppetTheaterEngineProvider = Provider<PuppetTheaterEngine>((ref) {
  return PuppetTheaterEngine();
});
