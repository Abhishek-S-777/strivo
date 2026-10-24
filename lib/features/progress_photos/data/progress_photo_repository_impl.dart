import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:strivo/features/progress_photos/domain/entities/progress_photo.dart';
import 'package:strivo/features/progress_photos/domain/progress_photo_repository.dart';

/// [ProgressPhotoRepository] backed by a dedicated Hive box. The box is opened
/// lazily on first use and cached for the app's lifetime.
class ProgressPhotoRepositoryImpl implements ProgressPhotoRepository {
  ProgressPhotoRepositoryImpl();

  static const String _boxName = 'progress_photos';
  Box<String>? _box;

  Future<Box<String>> _openBox() async =>
      _box ??= await Hive.openBox<String>(_boxName);

  @override
  Future<List<ProgressPhoto>> loadAll() async {
    final box = await _openBox();
    return box.values
        .map(
          (json) =>
              ProgressPhoto.fromMap(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> save(ProgressPhoto photo) async {
    final box = await _openBox();
    await box.put(photo.id, jsonEncode(photo.toMap()));
  }

  @override
  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}

/// Supplies the app-wide [ProgressPhotoRepository] implementation.
final progressPhotoRepositoryProvider = Provider<ProgressPhotoRepository>((
  ref,
) {
  return ProgressPhotoRepositoryImpl();
});
