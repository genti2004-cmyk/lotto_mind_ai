import 'draw_result.dart';
import 'draw_type.dart';

enum DrawDataStatusLevel {
  none,
  incomplete,
  needsUpdate,
  ready,
}

class DrawDataStatus {
  final DrawDataStatusLevel level;
  final DrawResult? latestDraw;
  final DrawResult? latestWednesday;
  final DrawResult? latestSaturday;
  final int totalDraws;
  final int coreCompleteDraws;
  final int additionalCompleteDraws;
  final int? ageDays;

  const DrawDataStatus({
    required this.level,
    required this.latestDraw,
    required this.latestWednesday,
    required this.latestSaturday,
    required this.totalDraws,
    required this.coreCompleteDraws,
    required this.additionalCompleteDraws,
    required this.ageDays,
  });

  bool get hasDraws => totalDraws > 0;
  bool get hasWednesday => latestWednesday != null;
  bool get hasSaturday => latestSaturday != null;
  bool get hasBothDrawDays => hasWednesday && hasSaturday;
  bool get hasCurrentCoreData => level == DrawDataStatusLevel.ready;
  bool get needsUpdate => level != DrawDataStatusLevel.ready;

  String get title {
    switch (level) {
      case DrawDataStatusLevel.none:
        return 'Keine Ziehungsdaten';
      case DrawDataStatusLevel.incomplete:
        return 'Daten unvollständig';
      case DrawDataStatusLevel.needsUpdate:
        return 'Daten aktualisieren empfohlen';
      case DrawDataStatusLevel.ready:
        return 'Datenbasis bereit';
    }
  }

  String get shortLabel {
    switch (level) {
      case DrawDataStatusLevel.none:
        return 'keine Daten';
      case DrawDataStatusLevel.incomplete:
        return 'unvollständig';
      case DrawDataStatusLevel.needsUpdate:
        return 'prüfen';
      case DrawDataStatusLevel.ready:
        return 'bereit';
    }
  }

  String get guidance {
    switch (level) {
      case DrawDataStatusLevel.none:
        return 'Aktualisiere zuerst die Ziehungen, damit Analyse und Generator sinnvoll arbeiten können.';
      case DrawDataStatusLevel.incomplete:
        return 'Mittwoch- oder Samstag-Daten fehlen. Aktualisiere die Ziehungen für eine saubere Analysebasis.';
      case DrawDataStatusLevel.needsUpdate:
        return 'Die neuesten gespeicherten Ziehungen wirken älter. Eine Aktualisierung wird empfohlen.';
      case DrawDataStatusLevel.ready:
        return 'Lottozahlen und Superzahl sind als Pflichtdaten vorhanden. Zusatzlotterien bleiben optional.';
    }
  }

  String get coreDataLabel {
    if (totalDraws == 0) return 'nicht vorhanden';
    if (coreCompleteDraws == totalDraws) return 'vollständig';
    return '$coreCompleteDraws von $totalDraws vollständig';
  }

  String get additionalDataLabel {
    if (totalDraws == 0) return 'nicht verfügbar';
    if (additionalCompleteDraws == totalDraws) return 'vollständig';
    if (additionalCompleteDraws > 0) return 'teilweise verfügbar';
    return 'nicht verfügbar';
  }

  String get analysisBaseLabel {
    if (totalDraws == 0) return 'keine Ziehungen';
    return '$totalDraws echte Ziehung${totalDraws == 1 ? '' : 'en'}';
  }

  static DrawDataStatus fromDraws(
    List<DrawResult> draws, {
    DateTime? now,
    int maxCurrentAgeDays = 10,
  }) {
    final referenceDate = now ?? DateTime.now();
    DrawResult? latest;
    DrawResult? latestWednesday;
    DrawResult? latestSaturday;
    var coreComplete = 0;
    var additionalComplete = 0;

    for (final draw in draws) {
      if (_hasCoreData(draw)) coreComplete++;
      if (_hasAdditionalData(draw)) additionalComplete++;

      if (latest == null || draw.drawDate.isAfter(latest.drawDate)) {
        latest = draw;
      }

      final type = DrawTypeX.fromDate(draw.drawDate);
      if (type == DrawType.wednesday &&
          (latestWednesday == null || draw.drawDate.isAfter(latestWednesday.drawDate))) {
        latestWednesday = draw;
      }
      if (type == DrawType.saturday &&
          (latestSaturday == null || draw.drawDate.isAfter(latestSaturday.drawDate))) {
        latestSaturday = draw;
      }
    }

    final ageDays = latest == null
        ? null
        : DateTime(
            referenceDate.year,
            referenceDate.month,
            referenceDate.day,
          ).difference(DateTime(
            latest.drawDate.year,
            latest.drawDate.month,
            latest.drawDate.day,
          )).inDays;

    final DrawDataStatusLevel level;
    if (draws.isEmpty || latest == null) {
      level = DrawDataStatusLevel.none;
    } else if (latestWednesday == null || latestSaturday == null || coreComplete == 0) {
      level = DrawDataStatusLevel.incomplete;
    } else if (ageDays == null || ageDays > maxCurrentAgeDays) {
      level = DrawDataStatusLevel.needsUpdate;
    } else {
      level = DrawDataStatusLevel.ready;
    }

    return DrawDataStatus(
      level: level,
      latestDraw: latest,
      latestWednesday: latestWednesday,
      latestSaturday: latestSaturday,
      totalDraws: draws.length,
      coreCompleteDraws: coreComplete,
      additionalCompleteDraws: additionalComplete,
      ageDays: ageDays,
    );
  }

  static bool _hasCoreData(DrawResult draw) {
    final numbers = draw.numbers.where((n) => n >= 1 && n <= 49).toSet();
    return numbers.length == 6 && draw.superNumber != null;
  }

  static bool _hasAdditionalData(DrawResult draw) {
    return (draw.spiel77?.trim().isNotEmpty ?? false) &&
        (draw.super6?.trim().isNotEmpty ?? false);
  }
}
