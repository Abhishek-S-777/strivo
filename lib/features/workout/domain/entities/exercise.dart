import 'package:flutter/foundation.dart';

/// Muscle group categories
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  legs,
  glutes,
  core,
  fullBody,
  cardio,
  other
  ;

  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.fullBody:
        return 'Full Body';
      case MuscleGroup.cardio:
        return 'Cardio';
      case MuscleGroup.other:
        return 'Other';
    }
  }
}

/// Equipment type
enum Equipment {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  kettlebell,
  band,
  other
  ;

  String get displayName {
    switch (this) {
      case Equipment.barbell:
        return 'Barbell';
      case Equipment.dumbbell:
        return 'Dumbbell';
      case Equipment.machine:
        return 'Machine';
      case Equipment.cable:
        return 'Cable';
      case Equipment.bodyweight:
        return 'Bodyweight';
      case Equipment.kettlebell:
        return 'Kettlebell';
      case Equipment.band:
        return 'Band';
      case Equipment.other:
        return 'Other';
    }
  }
}

/// Represents an exercise definition (template)
@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.equipment,
    this.secondaryMuscle,
    this.notes,
    this.isCustom = false,
    this.alternativeIds = const [],
    this.videoUrl,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      primaryMuscle: MuscleGroup.values.firstWhere(
        (e) => e.name == map['primaryMuscle'],
        orElse: () => MuscleGroup.other,
      ),
      secondaryMuscle: map['secondaryMuscle'] != null
          ? MuscleGroup.values.firstWhere(
              (e) => e.name == map['secondaryMuscle'],
              orElse: () => MuscleGroup.other,
            )
          : null,
      equipment: Equipment.values.firstWhere(
        (e) => e.name == map['equipment'],
        orElse: () => Equipment.other,
      ),
      notes: map['notes'] as String?,
      isCustom: map['isCustom'] as bool? ?? false,
      alternativeIds:
          (map['alternativeIds'] as List?)?.map((e) => e as String).toList() ??
          const [],
      videoUrl: map['videoUrl'] as String?,
    );
  }
  final String id;
  final String name;
  final MuscleGroup primaryMuscle;
  final MuscleGroup? secondaryMuscle;
  final Equipment equipment;
  final String? notes;
  final bool isCustom;

  /// Ids of exercises that can substitute for this one when the required
  /// machine/setup isn't available (e.g. Jeff Nippard's per-exercise
  /// alternatives). Resolve against the exercise library by id.
  final List<String> alternativeIds;

  /// Optional demo/tutorial video link (usually YouTube). When absent, the UI
  /// falls back to a YouTube search for the exercise name.
  final String? videoUrl;

  bool get hasAlternatives => alternativeIds.isNotEmpty;

  /// True when the user pinned a specific video (vs. relying on search).
  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'primaryMuscle': primaryMuscle.name,
      'secondaryMuscle': secondaryMuscle?.name,
      'equipment': equipment.name,
      'notes': notes,
      'isCustom': isCustom,
      'alternativeIds': alternativeIds,
      'videoUrl': videoUrl,
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    MuscleGroup? primaryMuscle,
    MuscleGroup? secondaryMuscle,
    Equipment? equipment,
    String? notes,
    bool? isCustom,
    List<String>? alternativeIds,
    String? videoUrl,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscle: secondaryMuscle ?? this.secondaryMuscle,
      equipment: equipment ?? this.equipment,
      notes: notes ?? this.notes,
      isCustom: isCustom ?? this.isCustom,
      alternativeIds: alternativeIds ?? this.alternativeIds,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
