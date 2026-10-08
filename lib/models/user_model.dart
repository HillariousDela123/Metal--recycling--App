/// Represents an authenticated user profile in the metal recycling app.
class UserModel {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final double totalRecycledKg;
  final int ecoPoints;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.totalRecycledKg = 0.0,
    this.ecoPoints = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'totalRecycledKg': totalRecycledKg,
      'ecoPoints': ecoPoints,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return UserModel(
      userId: documentId ?? map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      totalRecycledKg: (map['totalRecycledKg'] as num?)?.toDouble() ?? 0.0,
      ecoPoints: (map['ecoPoints'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    double? totalRecycledKg,
    int? ecoPoints,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      totalRecycledKg: totalRecycledKg ?? this.totalRecycledKg,
      ecoPoints: ecoPoints ?? this.ecoPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
