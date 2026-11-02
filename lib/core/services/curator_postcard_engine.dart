import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PostcardTheme {
  warmPaper,
  darkCarbon,
  matchaMint,
}

enum PostcardAspectRatio {
  square1x1,
  story9x16,
}

class CuratorPostcard {
  final String placeId;
  final String placeName;
  final String district;
  final String atmosphereTag;
  final String verifiedSeal;
  final String nearestSubway;
  final String curatorName;
  final String curatorHandle;
  final String curatorTier;
  final int curatorXp;
  final DateTime visitTimestamp;
  final String receiptNumber;
  final int itemsVisitedCount;
  final PostcardTheme theme;
  final PostcardAspectRatio aspectRatio;

  const CuratorPostcard({
    required this.placeId,
    required this.placeName,
    required this.district,
    required this.atmosphereTag,
    required this.verifiedSeal,
    required this.nearestSubway,
    required this.curatorName,
    required this.curatorHandle,
    required this.curatorTier,
    required this.curatorXp,
    required this.visitTimestamp,
    required this.receiptNumber,
    this.itemsVisitedCount = 1,
    this.theme = PostcardTheme.warmPaper,
    this.aspectRatio = PostcardAspectRatio.story9x16,
  });

  CuratorPostcard copyWith({
    PostcardTheme? theme,
    PostcardAspectRatio? aspectRatio,
  }) {
    return CuratorPostcard(
      placeId: placeId,
      placeName: placeName,
      district: district,
      atmosphereTag: atmosphereTag,
      verifiedSeal: verifiedSeal,
      nearestSubway: nearestSubway,
      curatorName: curatorName,
      curatorHandle: curatorHandle,
      curatorTier: curatorTier,
      curatorXp: curatorXp,
      visitTimestamp: visitTimestamp,
      receiptNumber: receiptNumber,
      itemsVisitedCount: itemsVisitedCount,
      theme: theme ?? this.theme,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'place_name': placeName,
    'district': district,
    'atmosphere_tag': atmosphereTag,
    'verified_seal': verifiedSeal,
    'nearest_subway': nearestSubway,
    'curator_name': curatorName,
    'curator_handle': curatorHandle,
    'curator_tier': curatorTier,
    'curator_xp': curatorXp,
    'visit_timestamp': visitTimestamp.toIso8601String(),
    'receipt_number': receiptNumber,
    'items_visited_count': itemsVisitedCount,
    'theme': theme.name,
    'aspect_ratio': aspectRatio.name,
  };

  factory CuratorPostcard.fromJson(Map<String, dynamic> json) => CuratorPostcard(
    placeId: json['place_id']?.toString() ?? '',
    placeName: json['place_name']?.toString() ?? '',
    district: json['district']?.toString() ?? '',
    atmosphereTag: json['atmosphere_tag']?.toString() ?? '',
    verifiedSeal: json['verified_seal']?.toString() ?? 'AR-0000-0000',
    nearestSubway: json['nearest_subway']?.toString() ?? '',
    curatorName: json['curator_name']?.toString() ?? '',
    curatorHandle: json['curator_handle']?.toString() ?? '',
    curatorTier: json['curator_tier']?.toString() ?? 'neighborhoodScout',
    curatorXp: (json['curator_xp'] as num?)?.toInt() ?? 0,
    visitTimestamp: json['visit_timestamp'] != null
        ? DateTime.tryParse(json['visit_timestamp'].toString()) ?? DateTime.now()
        : DateTime.now(),
    receiptNumber: json['receipt_number']?.toString() ?? 'REC-TAS-001',
    itemsVisitedCount: (json['items_visited_count'] as num?)?.toInt() ?? 1,
    theme: PostcardTheme.values.firstWhere(
      (e) => e.name == json['theme'],
      orElse: () => PostcardTheme.warmPaper,
    ),
    aspectRatio: PostcardAspectRatio.values.firstWhere(
      (e) => e.name == json['aspect_ratio'],
      orElse: () => PostcardAspectRatio.story9x16,
    ),
  );
}

class CuratorPostcardEngine {
  static String generateReceiptNumber([String district = 'Mirabad']) {
    final cleanDistrict = district.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final prefix = cleanDistrict.length >= 3 ? cleanDistrict.substring(0, 3) : 'TAS';
    final rand = (100 + math.Random().nextInt(900)).toString();
    return 'REC-$prefix-${DateTime.now().year}-$rand';
  }

  static CuratorPostcard createPostcard({
    required String placeId,
    required String placeName,
    required String district,
    required String atmosphereTag,
    required String verifiedSeal,
    required String nearestSubway,
    required String curatorName,
    required String curatorHandle,
    required String curatorTier,
    required int curatorXp,
    int itemsVisitedCount = 1,
    PostcardTheme theme = PostcardTheme.warmPaper,
    PostcardAspectRatio aspectRatio = PostcardAspectRatio.story9x16,
    DateTime? timestamp,
  }) {
    return CuratorPostcard(
      placeId: placeId,
      placeName: placeName,
      district: district,
      atmosphereTag: atmosphereTag,
      verifiedSeal: verifiedSeal,
      nearestSubway: nearestSubway,
      curatorName: curatorName,
      curatorHandle: curatorHandle,
      curatorTier: curatorTier,
      curatorXp: curatorXp,
      visitTimestamp: timestamp ?? DateTime.now(),
      receiptNumber: generateReceiptNumber(district),
      itemsVisitedCount: itemsVisitedCount,
      theme: theme,
      aspectRatio: aspectRatio,
    );
  }

  static String getLocalizedThemeName(PostcardTheme theme, String lang) {
    if (lang == 'uz') {
      switch (theme) {
        case PostcardTheme.warmPaper:
          return 'Issiq Qog‘oz';
        case PostcardTheme.darkCarbon:
          return 'To‘q Karbon';
        case PostcardTheme.matchaMint:
          return 'Yalpiz Matcha';
      }
    } else if (lang == 'ru') {
      switch (theme) {
        case PostcardTheme.warmPaper:
          return 'Тёплая бумага';
        case PostcardTheme.darkCarbon:
          return 'Тёмный карбон';
        case PostcardTheme.matchaMint:
          return 'Мятный матча';
      }
    }
    switch (theme) {
      case PostcardTheme.warmPaper:
        return 'Warm Paper';
      case PostcardTheme.darkCarbon:
        return 'Dark Carbon';
      case PostcardTheme.matchaMint:
        return 'Matcha Mint';
    }
  }

  static String getLocalizedReceiptHeader(String lang) {
    if (lang == 'uz') {
      return 'TOSHKENT MADANIY CHEKI & KARTA';
    } else if (lang == 'ru') {
      return 'ТАШКЕНТСКИЙ КУЛЬТУРНЫЙ ЧЕК';
    }
    return 'TASHKENT CULTURAL RECEIPT';
  }
}

final curatorPostcardEngineProvider = Provider<CuratorPostcardEngine>((ref) {
  return CuratorPostcardEngine();
});
