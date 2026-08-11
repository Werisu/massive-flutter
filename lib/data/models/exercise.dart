import 'enums.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.instructions,
  });

  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? instructions;

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscleGroup': muscleGroup.name,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'instructions': instructions,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        muscleGroup: MuscleGroup.values.byName(json['muscleGroup'] as String),
        description: json['description'] as String?,
        videoUrl: json['videoUrl'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        instructions: json['instructions'] as String?,
      );
}
