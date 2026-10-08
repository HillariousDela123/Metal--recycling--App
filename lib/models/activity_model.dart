/// Represents an audit log entry or user recycling history milestone.
class ActivityModel {
  final String activityId;
  final String userId;
  final String planId;
  final String action; // e.g., 'PLAN_CREATED', 'STATUS_UPDATED', 'METALS_DROPPED_OFF'
  final String title;
  final String description;
  final double? weightKg;
  final String? metalType;
  final DateTime timestamp;

  const ActivityModel({
    required this.activityId,
    required this.userId,
    required this.planId,
    required this.action,
    required this.title,
    required this.description,
    this.weightKg,
    this.metalType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'userId': userId,
      'planId': planId,
      'action': action,
      'title': title,
      'description': description,
      'weightKg': weightKg,
      'metalType': metalType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return ActivityModel(
      activityId: documentId ?? map['activityId'] ?? '',
      userId: map['userId'] ?? '',
      planId: map['planId'] ?? '',
      action: map['action'] ?? '',
      title: map['title'] ?? 'Recycling Activity',
      description: map['description'] ?? '',
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      metalType: map['metalType'],
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ActivityModel copyWith({
    String? activityId,
    String? userId,
    String? planId,
    String? action,
    String? title,
    String? description,
    double? weightKg,
    String? metalType,
    DateTime? timestamp,
  }) {
    return ActivityModel(
      activityId: activityId ?? this.activityId,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      action: action ?? this.action,
      title: title ?? this.title,
      description: description ?? this.description,
      weightKg: weightKg ?? this.weightKg,
      metalType: metalType ?? this.metalType,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
