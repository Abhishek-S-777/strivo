import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/progress_photos/domain/entities/progress_photo.dart';

/// A square thumbnail in the progress-photo timeline grid, with a date overlay
/// and an optional body-weight badge.
class PhotoThumbnail extends StatelessWidget {
  const PhotoThumbnail({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });
  final ProgressPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, e, st) => const ColoredBox(
                color: AppColors.surfaceLight,
                child: Icon(
                  LucideIcons.imageOff,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            // Date overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(180),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  DateFormat('MMM d').format(photo.date),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Body weight badge
            if (photo.bodyWeight != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${photo.bodyWeight!.toStringAsFixed(1)}kg',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
