import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:strivo/app.dart';
import 'package:strivo/core/services/hive_service.dart';
import 'package:strivo/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // On-brand error boundary: a widget that throws while building should never
  // leave the user staring at a blank/white area. Show a dark, readable card
  // instead (with the real error surfaced in debug builds).
  ErrorWidget.builder = (FlutterErrorDetails details) => _StrivoErrorView(details);

  // Initialize Hive (offline-first local storage)
  await Hive.initFlutter();
  await HiveService.init();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized (project: strivo-gym)');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('   App will run in offline-only mode (Hive).');
  }

  runApp(const ProviderScope(child: StrivoApp()));
}

/// Fallback shown in place of any widget that throws during build — dark and
/// on-brand, so a render failure degrades gracefully instead of blanking out.
class _StrivoErrorView extends StatelessWidget {
  final FlutterErrorDetails details;
  const _StrivoErrorView(this.details);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF141414),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFADC6FF), size: 36),
            const SizedBox(height: 12),
            const Text(
              "Couldn't display this",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
