import 'package:flutter/foundation.dart';

/// A progress photo entry
@immutable
class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.imagePath,
    required this.date,
    this.note,
    this.bodyWeight,
  });

  factory ProgressPhoto.fromMap(Map<String, dynamic> map) {
    return ProgressPhoto(
      id: map['id'] as String,
      imagePath: map['imagePath'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      bodyWeight: (map['bodyWeight'] as num?)?.toDouble(),
    );
  }
  final String id;
  final String imagePath;
  final DateTime date;
  final String? note;
  final double? bodyWeight;

  ProgressPhoto copyWith({
    String? id,
    String? imagePath,
    DateTime? date,
    String? note,
    double? bodyWeight,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      date: date ?? this.date,
      note: note ?? this.note,
      bodyWeight: bodyWeight ?? this.bodyWeight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'note': note,
      'bodyWeight': bodyWeight,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressPhoto &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
