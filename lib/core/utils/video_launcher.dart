import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';

/// Opens a demo/tutorial video for an exercise.
///
/// If the exercise has a pinned [Exercise.videoUrl] it opens that; otherwise it
/// falls back to a YouTube search for the exercise name — so *every* exercise
/// has a working "watch" action with zero data entry required.
class ExerciseVideo {
  ExerciseVideo._();

  /// The best video destination for [exercise] (pinned URL or search fallback).
  static Uri uriFor(Exercise exercise) {
    if (exercise.hasVideo) {
      final raw = exercise.videoUrl!.trim();
      final parsed = Uri.tryParse(raw);
      if (parsed != null && parsed.hasScheme) return parsed;
      // Tolerate links pasted without a scheme, e.g. "youtube.com/watch?v=…".
      return Uri.parse('https://$raw');
    }
    final query = Uri.encodeComponent('${exercise.name} exercise form');
    return Uri.parse('https://www.youtube.com/results?search_query=$query');
  }

  /// Launch the video in the YouTube app / browser. Returns false (rather than
  /// throwing) if no handler is available, so callers can show a message.
  static Future<bool> open(Exercise exercise) async {
    final uri = uriFor(exercise);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('⚠️ Could not open video for ${exercise.name}: $e');
      return false;
    }
  }
}
