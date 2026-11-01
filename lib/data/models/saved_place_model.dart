import 'place_model.dart';

class SavedPlaceModel {
  final String id;
  final String userId;
  final String placeId;
  final String status; // 'want_to_go', 'been', 'favorite'
  final DateTime createdAt;
  final PlaceModel? place;

  const SavedPlaceModel({
    required this.id,
    required this.userId,
    required this.placeId,
    this.status = 'want_to_go',
    required this.createdAt,
    this.place,
  });

  factory SavedPlaceModel.fromJson(Map<String, dynamic> json) {
    return SavedPlaceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      placeId: json['place_id'] as String,
      status: json['status'] as String? ?? 'want_to_go',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      place: json['places'] != null
          ? PlaceModel.fromJson(json['places'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FriendPlanModel {
  final String id;
  final String placeId;
  final String placeName;
  final List<String> attendeeInitials;
  final String scheduleTime;
  final String note;

  const FriendPlanModel({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.attendeeInitials,
    required this.scheduleTime,
    this.note = '',
  });

  factory FriendPlanModel.fromJson(Map<String, dynamic> json) {
    return FriendPlanModel(
      id: json['id'] as String,
      placeId: json['place_id'] as String,
      placeName: json['place_name'] as String? ?? 'Venue',
      attendeeInitials: (json['attendee_initials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['YO'],
      scheduleTime: json['schedule_time'] as String? ?? 'Sat 10:30 AM',
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_id': placeId,
      'place_name': placeName,
      'attendee_initials': attendeeInitials,
      'schedule_time': scheduleTime,
      'note': note,
    };
  }
}
