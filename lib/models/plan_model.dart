/// Status of a metal recycling schedule plan.
enum PlanStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case PlanStatus.pending:
        return 'Pending';
      case PlanStatus.confirmed:
        return 'Confirmed';
      case PlanStatus.completed:
        return 'Completed';
      case PlanStatus.cancelled:
        return 'Cancelled';
    }
  }

  static PlanStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return PlanStatus.confirmed;
      case 'completed':
        return PlanStatus.completed;
      case 'cancelled':
        return PlanStatus.cancelled;
      case 'pending':
      default:
        return PlanStatus.pending;
    }
  }
}

/// Represents a scheduled recycling drop-off plan.
class PlanModel {
  final String planId;
  final String userId;
  final String serviceId;
  final String serviceName;
  final String metalType;
  final double weightKg;
  final DateTime date;
  final PlanStatus status;
  final String notes;
  final bool reminderEnabled;
  final DateTime createdAt;

  const PlanModel({
    required this.planId,
    required this.userId,
    required this.serviceId,
    this.serviceName = '',
    required this.metalType,
    this.weightKg = 1.0,
    required this.date,
    this.status = PlanStatus.pending,
    this.notes = '',
    this.reminderEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'metalType': metalType,
      'weightKg': weightKg,
      'date': date.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlanModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return PlanModel(
      planId: documentId ?? map['planId'] ?? '',
      userId: map['userId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      metalType: map['metalType'] ?? '',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 1.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      status: PlanStatus.fromString(map['status']),
      notes: map['notes'] ?? '',
      reminderEnabled: map['reminderEnabled'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PlanModel copyWith({
    String? planId,
    String? userId,
    String? serviceId,
    String? serviceName,
    String? metalType,
    double? weightKg,
    DateTime? date,
    PlanStatus? status,
    String? notes,
    bool? reminderEnabled,
    DateTime? createdAt,
  }) {
    return PlanModel(
      planId: planId ?? this.planId,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      metalType: metalType ?? this.metalType,
      weightKg: weightKg ?? this.weightKg,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
