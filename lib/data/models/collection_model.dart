class CollectionModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String audience; // 'private', 'friends', 'public'
  final bool isCollaborative;
  final DateTime createdAt;
  final List<String> placeIds;

  const CollectionModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description = '',
    this.audience = 'friends',
    this.isCollaborative = false,
    required this.createdAt,
    this.placeIds = const [],
  });

  CollectionModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? audience,
    bool? isCollaborative,
    DateTime? createdAt,
    List<String>? placeIds,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      audience: audience ?? this.audience,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      createdAt: createdAt ?? this.createdAt,
      placeIds: placeIds ?? this.placeIds,
    );
  }

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    final items = json['collection_items'] as List<dynamic>?;
    final List<String> pIds = [];
    if (items != null) {
      for (final item in items) {
        if (item is Map) {
          final placeMap = item['places'] is Map ? item['places'] as Map : null;
          final slugOrId = placeMap?['slug']?.toString() ?? item['place_id']?.toString() ?? '';
          if (slugOrId.isNotEmpty) pIds.add(slugOrId);
        }
      }
    }

    return CollectionModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      audience: json['audience'] as String? ?? 'friends',
      isCollaborative: json['is_collaborative'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      placeIds: pIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'audience': audience,
      'is_collaborative': isCollaborative,
      'created_at': createdAt.toIso8601String(),
      'place_ids': placeIds,
    };
  }
}
