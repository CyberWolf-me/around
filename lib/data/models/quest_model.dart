class QuestModel {
  final String id;
  final String title;
  final String description;
  final String district;
  final String category;
  final String icon;
  final String badgeName;
  final List<String> targetPlaceIds;
  final int requiredCount;

  const QuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.district,
    required this.category,
    required this.icon,
    required this.badgeName,
    required this.targetPlaceIds,
    required this.requiredCount,
  });

  /// Checks if the quest is fully completed based on user's visited venue IDs.
  bool isCompleted(Set<String> visitedPlaceIds) {
    return completedCount(visitedPlaceIds) >= requiredCount;
  }

  /// Calculates the fraction completed (0.0 to 1.0).
  double progressFraction(Set<String> visitedPlaceIds) {
    if (requiredCount <= 0) return 1.0;
    return (completedCount(visitedPlaceIds) / requiredCount).clamp(0.0, 1.0);
  }

  /// Counts how many of the target places have been visited.
  int completedCount(Set<String> visitedPlaceIds) {
    return targetPlaceIds.where(visitedPlaceIds.contains).length;
  }

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      district: json['district'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      badgeName: json['badge_name'] as String,
      targetPlaceIds: (json['target_place_ids'] as List<dynamic>).map((e) => e.toString()).toList(),
      requiredCount: json['required_count'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'district': district,
      'category': category,
      'icon': icon,
      'badge_name': badgeName,
      'target_place_ids': targetPlaceIds,
      'required_count': requiredCount,
    };
  }
}
