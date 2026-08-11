import '../models/user_preferences.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.weight,
    this.height,
    this.age,
    this.gender,
    this.goal,
    this.experience,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final double? weight;
  final double? height;
  final int? age;
  final String? gender;
  final String? goal;
  final String? experience;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserPreferences toPreferences(UserPreferences current) {
    return current.copyWith(
      userName: name.isEmpty ? current.userName : name,
      weightKg: weight,
      heightCm: height,
      age: age,
      firebaseUid: id,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'weight': weight,
        'height': height,
        'age': age,
        'gender': gender,
        'goal': goal,
        'experience': experience,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

  factory UserProfile.fromFirestore(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      goal: json['goal'] as String?,
      experience: json['experience'] as String?,
      createdAt: _ms(json['createdAt']),
      updatedAt: _ms(json['updatedAt']),
    );
  }

  static DateTime? _ms(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
