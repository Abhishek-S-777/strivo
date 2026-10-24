import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:strivo/core/logging/app_logger.dart';
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/progress_photos/data/progress_photo_repository_impl.dart';
import 'package:strivo/features/progress_photos/domain/entities/progress_photo.dart';
import 'package:strivo/features/progress_photos/domain/progress_photo_repository.dart';

final progressPhotosProvider =
    StateNotifierProvider<ProgressPhotosNotifier, List<ProgressPhoto>>((ref) {
      return ProgressPhotosNotifier(ref.watch(progressPhotoRepositoryProvider));
    });

class ProgressPhotosNotifier extends StateNotifier<List<ProgressPhoto>> {
  ProgressPhotosNotifier(this._repo) : super([]) {
    unawaited(_load());
  }

  final ProgressPhotoRepository _repo;
  final ImagePicker _picker = ImagePicker();

  Future<void> _load() async {
    state = await _repo.loadAll();
  }

  Future<ProgressPhoto?> addPhoto({
    String? note,
    double? bodyWeight,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Save to app's document directory
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'strivo_photos'));
      if (!photosDir.existsSync()) {
        await photosDir.create(recursive: true);
      }

      final id = IdGenerator.generate();
      final ext = p.extension(image.path);
      final filename = 'photo_$id$ext';
      final savedPath = p.join(photosDir.path, filename);

      await File(image.path).copy(savedPath);

      final photo = ProgressPhoto(
        id: id,
        imagePath: savedPath,
        date: DateTime.now(),
        note: note,
        bodyWeight: bodyWeight,
      );

      await _repo.save(photo);
      await _load();
      return photo;
    } on Object catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to add progress photo',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> deletePhoto(String id) async {
    final photo = state.firstWhere((p) => p.id == id);
    // Delete the file
    try {
      final file = File(photo.imagePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object catch (e, stackTrace) {
      // Best-effort cleanup; the Hive record is removed regardless.
      AppLogger.warning(
        'Failed to delete photo file',
        error: e,
        stackTrace: stackTrace,
      );
    }

    await _repo.delete(id);
    await _load();
  }

  Future<void> updatePhotoNote(String id, String note) async {
    final photo = state.firstWhere((p) => p.id == id);
    await _repo.save(photo.copyWith(note: note));
    await _load();
  }

  List<ProgressPhoto> getPhotosByMonth(int year, int month) {
    return state
        .where((p) => p.date.year == year && p.date.month == month)
        .toList();
  }
}
