import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:strivo/core/units/weight_unit.dart';
import 'package:strivo/features/workout/domain/entities/exercise.dart';
import 'package:strivo/features/workout/domain/entities/workout_session.dart';

enum ExportFormat { csv, json, report }

/// Builds shareable exports of training history. CSV + the Markdown report use
/// the user's display unit (clearly labelled); JSON is canonical kilograms.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ── Public API ────────────────────────────────────────────────

  Future<void> share(ExportFormat format, List<WorkoutSession> sessions) async {
    final completed = sessions.where((s) => s.isCompleted).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final now = DateTime.now();
    final stamp = DateFormat('yyyy-MM-dd').format(now);

    late final String content;
    late final String filename;
    late final String subject;

    switch (format) {
      case ExportFormat.csv:
        content = buildCsv(completed);
        filename = 'strivo_export_$stamp.csv';
        subject = 'Strivo workout data (CSV)';
        break;
      case ExportFormat.json:
        content = buildJson(completed, now);
        filename = 'strivo_export_$stamp.json';
        subject = 'Strivo workout data (JSON)';
        break;
      case ExportFormat.report:
        content = buildReport(completed, now);
        filename = 'strivo_report_$stamp.md';
        subject = 'Strivo training report';
        break;
    }

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: _mime(format))],
      subject: subject,
      text: format == ExportFormat.report
          ? 'My Strivo training report — paste this to an AI to tune diet & recovery.'
          : subject,
    );
  }

  String _mime(ExportFormat f) {
    switch (f) {
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.json:
        return 'application/json';
      case ExportFormat.report:
        return 'text/markdown';
    }
  }

  // ── CSV (one row per set, display unit) ───────────────────────

  String buildCsv(List<WorkoutSession> sessions) {
    final u = Units.label;
    final b = StringBuffer();
    b.writeln('Date,Workout,Exercise,Muscle,Equipment,Set,Weight($u),'
        'Reps,RPE,Volume($u),PR,Warmup');
    final df = DateFormat('yyyy-MM-dd HH:mm');
    for (final s in sessions) {
      for (final we in s.exercises) {
        for (final set in we.sets.where((x) => x.isCompleted)) {
          b.writeln([
            df.format(s.startTime),
            _csv(s.name),
            _csv(we.exercise.name),
            we.exercise.primaryMuscle.displayName,
            we.exercise.equipment.displayName,
            set.setNumber,
            Units.fromKg(set.weight).toStringAsFixed(2),
            set.reps,
            set.rpe?.toString() ?? '',
            Units.fromKg(set.volume).toStringAsFixed(2),
            set.isPR ? 'yes' : '',
            set.isWarmup ? 'yes' : '',
          ].join(','));
        }
      }
    }
    return b.toString();
  }

  String _csv(String v) =>
      v.contains(',') || v.contains('"') ? '"${v.replaceAll('"', '""')}"' : v;

  // ── JSON (canonical kg, lossless) ─────────────────────────────

  String buildJson(List<WorkoutSession> sessions, DateTime now) {
    final map = {
      'app': 'Strivo',
      'generatedAt': now.toIso8601String(),
      'weightsStoredIn': 'kg',
      'preferredDisplayUnit': Units.label,
      'summary': _summary(sessions),
      'sessions': sessions.map((s) => s.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  // ── Markdown report (display unit, AI-friendly) ───────────────

  String buildReport(List<WorkoutSession> sessions, DateTime now) {
    final u = Units.label;
    final b = StringBuffer();
    final sum = _summary(sessions);

    b.writeln('# Strivo Training Report');
    b.writeln();
    b.writeln('_Generated ${DateFormat('EEEE, MMM d, yyyy').format(now)} · '
        'all weights in **$u**._');
    b.writeln();

    if (sessions.isEmpty) {
      b.writeln('No completed workouts yet.');
      return b.toString();
    }

    // Snapshot
    b.writeln('## Snapshot');
    b.writeln('- **Workouts logged:** ${sum['workouts']}');
    b.writeln('- **Total volume lifted:** ${Units.volumeLabel(sum['totalVolumeKg'] as double)}');
    b.writeln('- **Total working sets:** ${sum['totalSets']}');
    b.writeln('- **Time under the bar:** ${sum['hoursTrained']}h');
    b.writeln('- **Current weekly streak:** ${sum['streakWeeks']} week(s)');
    b.writeln('- **Training span:** ${sum['firstDate']} → ${sum['lastDate']}');
    b.writeln();

    // This week vs last
    final wk = _weekCompare(sessions);
    b.writeln('## This Week vs Last Week');
    b.writeln('| Metric | This week | Last week |');
    b.writeln('| --- | --- | --- |');
    b.writeln('| Workouts | ${wk['thisCount']} | ${wk['lastCount']} |');
    b.writeln('| Volume | ${Units.volumeLabel(wk['thisVol'] as double)} | '
        '${Units.volumeLabel(wk['lastVol'] as double)} |');
    final dv = wk['volDeltaPct'] as double;
    b.writeln('| Volume change | ${dv >= 0 ? '+' : ''}${dv.toStringAsFixed(1)}% | — |');
    b.writeln();

    // Top lifts (est 1RM + trend)
    final lifts = _liftBreakdown(sessions);
    if (lifts.isNotEmpty) {
      b.writeln('## Key Lifts (estimated 1RM via Epley)');
      b.writeln('| Exercise | Sessions | Best set | Est. 1RM | 4-wk change |');
      b.writeln('| --- | --- | --- | --- | --- |');
      for (final l in lifts.take(15)) {
        final ch = l.changeKg;
        final chStr = l.sessions < 2
            ? '—'
            : '${ch >= 0 ? '+' : ''}${Units.weight(ch)} $u';
        b.writeln('| ${l.name} | ${l.sessions} | '
            '${Units.weight(l.bestWeightKg)} $u × ${l.bestReps} | '
            '${Units.weight(l.est1rmKg)} $u | $chStr |');
      }
      b.writeln();
    }

    // Muscle distribution this week
    final dist = _muscleDistribution(sessions);
    if (dist.isNotEmpty) {
      b.writeln('## Muscle Focus (this week, by volume)');
      for (final e in dist) {
        b.writeln('- **${e.key}:** ${e.value.toStringAsFixed(0)}%');
      }
      b.writeln();
    }

    // Recent sessions
    b.writeln('## Recent Sessions');
    b.writeln('| Date | Workout | Duration | Volume | Sets | PRs |');
    b.writeln('| --- | --- | --- | --- | --- | --- |');
    for (final s in sessions.take(12)) {
      b.writeln('| ${DateFormat('MMM d').format(s.startTime)} | ${s.name} | '
          '${s.durationFormatted} | ${Units.volumeLabel(s.totalVolume)} | '
          '${s.totalCompletedSets} | ${s.prCount} |');
    }
    b.writeln();

    // AI guidance
    b.writeln('---');
    b.writeln('### How to use this report');
    b.writeln('This is a training summary from the Strivo app. Volume = '
        'weight × reps summed over completed working sets. Estimated 1RM uses '
        'the Epley formula `weight × (1 + reps/30)`.');
    b.writeln();
    b.writeln('**Suggested prompt for an AI:** "Here is my recent gym training '
        'data. Based on my volume trend, key-lift progression, muscle '
        'distribution and training frequency, suggest adjustments to my diet '
        '(calories/protein) and recovery (sleep, rest days, deloads) to keep '
        'progressing. Flag any over/undertrained muscle groups."');

    return b.toString();
  }

  // ── Aggregation helpers ───────────────────────────────────────

  Map<String, dynamic> _summary(List<WorkoutSession> sessions) {
    final totalVol =
        sessions.fold(0.0, (sum, s) => sum + s.totalVolume);
    final totalSets =
        sessions.fold(0, (sum, s) => sum + s.totalCompletedSets);
    final totalDur =
        sessions.fold(Duration.zero, (sum, s) => sum + s.duration);
    final dates = sessions.map((s) => s.startTime).toList()..sort();
    final df = DateFormat('MMM d, yyyy');
    return {
      'workouts': sessions.length,
      'totalVolumeKg': totalVol,
      'totalSets': totalSets,
      'hoursTrained': totalDur.inHours,
      'streakWeeks': _streakWeeks(sessions),
      'firstDate': dates.isEmpty ? '—' : df.format(dates.first),
      'lastDate': dates.isEmpty ? '—' : df.format(dates.last),
      'prs': sessions.fold(0, (sum, s) => sum + s.prCount),
    };
  }

  DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  int _streakWeeks(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;
    final weeks = sessions.map((s) => _weekStart(s.startTime)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final current = _weekStart(DateTime.now());
    final active = weeks.first == current ||
        weeks.first == current.subtract(const Duration(days: 7));
    if (!active) return 0;
    var streak = 0;
    var expected = weeks.first;
    for (final w in weeks) {
      if (w == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 7));
      } else if (w.isBefore(expected)) {
        break;
      }
    }
    return streak;
  }

  Map<String, dynamic> _weekCompare(List<WorkoutSession> sessions) {
    final thisStart = _weekStart(DateTime.now());
    final lastStart = thisStart.subtract(const Duration(days: 7));
    final thisWk =
        sessions.where((s) => !s.startTime.isBefore(thisStart)).toList();
    final lastWk = sessions
        .where((s) =>
            !s.startTime.isBefore(lastStart) && s.startTime.isBefore(thisStart))
        .toList();
    final thisVol = thisWk.fold(0.0, (a, s) => a + s.totalVolume);
    final lastVol = lastWk.fold(0.0, (a, s) => a + s.totalVolume);
    return {
      'thisCount': thisWk.length,
      'lastCount': lastWk.length,
      'thisVol': thisVol,
      'lastVol': lastVol,
      'volDeltaPct': lastVol > 0 ? (thisVol - lastVol) / lastVol * 100 : 0.0,
    };
  }

  List<MapEntry<String, double>> _muscleDistribution(
      List<WorkoutSession> sessions) {
    final thisStart = _weekStart(DateTime.now());
    final thisWk = sessions.where((s) => !s.startTime.isBefore(thisStart));
    final vol = <MuscleGroup, double>{};
    var total = 0.0;
    for (final s in thisWk) {
      for (final we in s.exercises) {
        vol[we.exercise.primaryMuscle] =
            (vol[we.exercise.primaryMuscle] ?? 0) + we.totalVolume;
        total += we.totalVolume;
      }
    }
    if (total == 0) return [];
    final entries = vol.entries
        .map((e) => MapEntry(e.key.displayName, e.value / total * 100))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<_Lift> _liftBreakdown(List<WorkoutSession> sessions) {
    // exerciseId -> chronological best-set records
    final data = <String, List<({DateTime date, double w, int reps})>>{};
    final names = <String, String>{};
    final ordered = [...sessions]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    for (final s in ordered) {
      for (final we in s.exercises) {
        final working = we.sets.where((x) => x.isCompleted && !x.isWarmup);
        if (working.isEmpty) continue;
        var bw = 0.0;
        var br = 0;
        for (final set in working) {
          if (set.weight > bw || (set.weight == bw && set.reps > br)) {
            bw = set.weight;
            br = set.reps;
          }
        }
        names[we.exercise.id] = we.exercise.name;
        data
            .putIfAbsent(we.exercise.id, () => [])
            .add((date: s.startTime, w: bw, reps: br));
      }
    }

    final lifts = <_Lift>[];
    final fourWeeksAgo = DateTime.now().subtract(const Duration(days: 28));
    for (final entry in data.entries) {
      final recs = entry.value;
      final latest = recs.last;
      final est = latest.reps > 0
          ? latest.w * (1 + latest.reps / 30)
          : latest.w;
      // 4-week change: latest max weight vs the max weight ~4 weeks ago
      final older =
          recs.where((r) => r.date.isBefore(fourWeeksAgo)).toList();
      final base = older.isNotEmpty ? older.last.w : recs.first.w;
      lifts.add(_Lift(
        name: names[entry.key] ?? 'Exercise',
        sessions: recs.length,
        bestWeightKg: latest.w,
        bestReps: latest.reps,
        est1rmKg: est,
        changeKg: latest.w - base,
      ));
    }
    lifts.sort((a, b) => b.est1rmKg.compareTo(a.est1rmKg));
    return lifts;
  }
}

class _Lift {
  final String name;
  final int sessions;
  final double bestWeightKg;
  final int bestReps;
  final double est1rmKg;
  final double changeKg;
  _Lift({
    required this.name,
    required this.sessions,
    required this.bestWeightKg,
    required this.bestReps,
    required this.est1rmKg,
    required this.changeKg,
  });
}
