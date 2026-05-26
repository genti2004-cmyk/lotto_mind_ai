import 'dart:convert';
import 'dart:io';

import '../domain/draw_result.dart';

/// Stabiler Import-Service fuer Lotto 6aus49.
///
/// Ziel dieser Version:
/// - nur gueltige Mittwoch-/Samstag-Ziehungen uebernehmen
/// - Hauptzahlen immer als 6 eindeutige Zahlen 1..49 validieren
/// - Superzahl 0..9 validieren
/// - Spiel 77 / Super 6 als reine Ziffernfolgen validieren
/// - Import-Ergebnis deduplizieren und immer neu -> alt sortieren
class LottoResultsImportService {
  static const String _dielottozahlendeYearUrl =
      'https://www.dielottozahlende.net/lotto-6-aus-49/year';
  static const String _lottozahlenOnlineArchiveUrl =
      'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php';
  static const String _lottosterLatestUrl =
      'https://www.lottoster.com/de/lotto-6aus49/results/';
  static const String _lottoNetLatestUrl =
      'https://www.lotto.net/de/deutsches-lotto/ergebnisse';

  Future<List<DrawResult>> fetchLatestResults() async {
    final urls = <String>[
      _lottosterLatestUrl,
      _lottoNetLatestUrl,
      '$_dielottozahlendeYearUrl/${DateTime.now().year}',
      '$_lottozahlenOnlineArchiveUrl?j=${DateTime.now().year}',
      'https://www.lottozahlenonline.de/',
    ];

    return _downloadAndParseAllWorking(urls);
  }

  Future<List<DrawResult>> fetchRecentResults({int weeks = 8}) async {
    final now = DateTime.now();
    final fromDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weeks * 7 + 3));

    final combined = <DrawResult>[];

    try {
      combined.addAll(await fetchLatestResults());
    } catch (_) {
      // Fallbacks unten versuchen weiter Daten zu laden.
    }

    final years = <int>{now.year, fromDate.year}.toList()..sort((a, b) => b.compareTo(a));
    for (final year in years) {
      try {
        combined.addAll(await fetchYearResults(year));
      } catch (_) {
        // Einzelne Quellen/Jahre duerfen fehlschlagen, solange andere Daten liefern.
      }
    }

    final recent = _normalizeResults(combined)
        .where((draw) => !draw.drawDate.isBefore(fromDate))
        .toList()
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    if (recent.isEmpty) {
      throw Exception('Keine aktuellen Ziehungen der letzten $weeks Wochen gefunden.');
    }

    return recent;
  }

  Future<List<DrawResult>> fetchYearResults(int year) async {
    final urls = <String>[
      '$_dielottozahlendeYearUrl/$year',
      '$_dielottozahlendeYearUrl?year=$year',
      '$_lottozahlenOnlineArchiveUrl?j=$year',
      '$_lottozahlenOnlineArchiveUrl?jahr=$year',
      _lottozahlenOnlineArchiveUrl,
      'https://www.lotto.net/de/deutsches-lotto/ergebnisse/$year',
      'https://www.lotto.net/german-lotto/results/$year',
    ];

    final parsed = await _downloadAndParseAllWorking(urls);
    return _normalizeResults(parsed)
        .where((draw) => draw.drawDate.year == year)
        .toList()
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));
  }

  Future<List<DrawResult>> _downloadAndParseAllWorking(List<String> urls) async {
    final combined = <DrawResult>[];
    Object? lastError;

    for (final url in urls) {
      try {
        final body = await _download(url);
        final parsed = _parseResultsFromHtml(body);
        final valid = _normalizeResults(parsed);
        if (valid.isNotEmpty) combined.addAll(valid);
      } catch (error) {
        lastError = error;
      }
    }

    final normalized = _normalizeResults(combined);
    if (normalized.isNotEmpty) return normalized;

    throw Exception('Import fehlgeschlagen: ${lastError ?? 'keine gueltigen Ziehungen gefunden'}');
  }

Future<String> _download(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 15)
      ..autoUncompress = true;

    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 5;
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36',
      );
      request.headers.set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      );
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'de-DE,de;q=0.9,en;q=0.8');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode} bei $url');
      }

      final bytes = await response
          .expand((chunk) => chunk)
          .toList()
          .timeout(const Duration(seconds: 30));
      return utf8.decode(bytes, allowMalformed: true);
    } finally {
      client.close(force: true);
    }
  }

  List<DrawResult> _parseResultsFromHtml(String html) {
    final text = _htmlToPlainText(html);
    final headings = _findHeadings(text);
    final results = <DrawResult>[];

    for (var i = 0; i < headings.length; i++) {
      final heading = headings[i];
      final start = heading.end;
      final end = i + 1 < headings.length ? headings[i + 1].start : text.length;
      final block = text.substring(start, end);

      final mainNumbers = _extractMainNumbers(block);
      if (mainNumbers.length != 6) continue;

      final superNumber = _extractSuperNumber(block, mainNumbers: mainNumbers);
      final spiel77 = _extractSpiel77(block);
      final super6 = _extractSuper6(block);

      results.add(
        DrawResult(
          id: _buildStableId(heading.drawDate, mainNumbers),
          drawDate: heading.drawDate,
          numbers: mainNumbers,
          superNumber: superNumber,
          spiel77: spiel77,
          super6: super6,
        ),
      );
    }

    return _normalizeResults(results);
  }

  List<DrawResult> _normalizeResults(List<DrawResult> input) {
    final byDate = <String, DrawResult>{};

    for (final draw in input) {
      if (!_isValidDrawDay(draw.drawDate)) continue;

      final numbers = _normalizeMainNumbers(draw.numbers);
      if (numbers.length != 6) continue;

      final superNumber = _normalizeSuperNumber(draw.superNumber);
      final spiel77 = _normalizeDigitGame(draw.spiel77, 7);
      final super6 = _normalizeDigitGame(draw.super6, 6);

      final normalized = DrawResult(
        id: _buildStableId(draw.drawDate, numbers),
        drawDate: DateTime(draw.drawDate.year, draw.drawDate.month, draw.drawDate.day),
        numbers: numbers,
        superNumber: superNumber,
        spiel77: spiel77,
        super6: super6,
      );

      final key = _dateKey(normalized.drawDate);
      final current = byDate[key];
      byDate[key] = current == null ? normalized : _mergeSameDate(current, normalized);
    }

    return byDate.values.toList()..sort((a, b) => b.drawDate.compareTo(a.drawDate));
  }

  DrawResult _mergeSameDate(DrawResult current, DrawResult incoming) {
    // Bei gleicher Ziehung bleibt die erste valide Zahlenreihe stabil.
    // Eine gefundene Superzahl aus einer spaeteren Quelle darf korrigieren;
    // null ueberschreibt innerhalb desselben Parser-Laufs nicht.
    return current.copyWith(
      superNumber: incoming.superNumber ?? current.superNumber,
      spiel77: incoming.spiel77 ?? current.spiel77,
      super6: incoming.super6 ?? current.super6,
    );
  }

  List<_DrawHeading> _findHeadings(String text) {
    final headings = <_DrawHeading>[];

    void addMatches(RegExp regex, DateTime? Function(RegExpMatch match) parser) {
      for (final match in regex.allMatches(text)) {
        final date = parser(match);
        if (date == null || !_isValidDrawDay(date)) continue;
        headings.add(_DrawHeading(match.start, match.end, DateTime(date.year, date.month, date.day)));
      }
    }

    addMatches(
      RegExp(
        r'\b(?:Wednesday|Saturday),?\s+(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)\s+(\d{4})\b',
        caseSensitive: false,
      ),
          (m) {
        final day = int.tryParse(m.group(1) ?? '');
        final month = _monthFromEnglish(m.group(2) ?? '');
        final year = int.tryParse(m.group(3) ?? '');
        if (day == null || month == null || year == null) return null;
        return DateTime(year, month, day);
      },
    );

    addMatches(
      RegExp(
        r'\b(?:Wednesday|Saturday)\s+([A-Za-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?\s+(\d{4})\b',
        caseSensitive: false,
      ),
          (m) {
        final month = _monthFromEnglish(m.group(1) ?? '');
        final day = int.tryParse(m.group(2) ?? '');
        final year = int.tryParse(m.group(3) ?? '');
        if (day == null || month == null || year == null) return null;
        return DateTime(year, month, day);
      },
    );

    addMatches(
      RegExp(
        r'\b(?:Lotto\s+am\s+)?(?:Samstag|Mittwoch)(?:\s+den|,)?\s+(\d{1,2})\.(\d{1,2})\.(\d{4})\b',
        caseSensitive: false,
      ),
          (m) {
        final day = int.tryParse(m.group(1) ?? '');
        final month = int.tryParse(m.group(2) ?? '');
        final year = int.tryParse(m.group(3) ?? '');
        if (day == null || month == null || year == null) return null;
        return DateTime(year, month, day);
      },
    );

    addMatches(
      RegExp(
        r'\b(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(?:Mittwoch|Samstag)\b',
        caseSensitive: false,
      ),
          (m) {
        final day = int.tryParse(m.group(1) ?? '');
        final month = int.tryParse(m.group(2) ?? '');
        final year = int.tryParse(m.group(3) ?? '');
        if (day == null || month == null || year == null) return null;
        return DateTime(year, month, day);
      },
    );

    headings.sort((a, b) => a.start.compareTo(b.start));

    final unique = <_DrawHeading>[];
    for (final heading in headings) {
      final duplicate = unique.any(
            (old) => old.drawDate.year == heading.drawDate.year &&
            old.drawDate.month == heading.drawDate.month &&
            old.drawDate.day == heading.drawDate.day &&
            (heading.start - old.start).abs() < 80,
      );
      if (!duplicate) unique.add(heading);
    }
    return unique;
  }

  List<int> _extractMainNumbers(String block) {
    final lines = block
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(80)
        .toList();

    final markerPatterns = <RegExp>[
      RegExp(r'\b(?:lottozahlen|gewinnzahlen|zahlen|winning numbers|numbers)\b[^\n]*', caseSensitive: false),
      RegExp(r'\b6\s*aus\s*49\b[^\n]*', caseSensitive: false),
    ];

    for (final line in lines) {
      if (_isNoiseLine(line)) continue;
      for (final marker in markerPatterns) {
        if (!marker.hasMatch(line)) continue;
        final candidate = _firstValidSixFromText(line);
        if (candidate.length == 6) return candidate;
      }
    }

    final beforeSuper = _textBeforeFirstSuperMarker(block);
    final direct = _firstValidSixFromCleanLines(beforeSuper);
    if (direct.length == 6) return direct;

    final fallback = _firstValidSixFromCleanLines(block);
    if (fallback.length == 6) return fallback;

    return const [];
  }

  List<int> _firstValidSixFromCleanLines(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(80);

    for (final line in lines) {
      if (_isNoiseLine(line)) continue;
      final candidate = _firstValidSixFromText(line);
      if (candidate.length == 6) return candidate;
    }
    return const [];
  }

  List<int> _firstValidSixFromText(String text) {
    final values = RegExp(r'\b(\d{1,2})\b')
        .allMatches(text)
        .map((m) => int.tryParse(m.group(1) ?? ''))
        .whereType<int>()
        .toList();

    if (values.length < 6) return const [];

    for (var start = 0; start <= values.length - 6; start++) {
      final window = values.sublist(start, start + 6);
      final normalized = _normalizeMainNumbers(window);
      if (normalized.length == 6) return normalized;
    }

    return const [];
  }

  bool _isNoiseLine(String line) {
    final lower = line.toLowerCase();
    const noiseWords = <String>[
      'jackpot',
      'quote',
      'quoten',
      'gewinnklasse',
      'gewinner',
      'gewinn',
      'million',
      'euro',
      'spiel 77',
      'spiel77',
      'super 6',
      'super6',
      'superzahl',
      'lottoquoten',
    ];
    if (noiseWords.any(lower.contains)) return true;
    if (line.contains('€')) return true;
    return false;
  }

  String _textBeforeFirstSuperMarker(String block) {
    final marker = RegExp(
      r'\b(?:Superzahl|SZ|S\.?Z\.?)\s*[:\-]?\s*\d\b',
      caseSensitive: false,
    ).firstMatch(block);
    if (marker == null) return block;
    return block.substring(0, marker.start);
  }

  int? _extractSuperNumber(
    String block, {
    required List<int> mainNumbers,
  }) {
    // Wichtig: Nicht generisch auf "Super 6" matchen.
    // Sonst wird die Zusatzlotterie "SUPER 6" als Superzahl 6 gelesen.
    final labelBeforeValuePatterns = <RegExp>[
      RegExp(r'\bSuperzahl\s*[:\-]?\s*(\d)\b', caseSensitive: false),
      RegExp(r'\bSZ\s*[:\-]?\s*(\d)\b', caseSensitive: false),
      RegExp(r'\bS\.?Z\.?\s*[:\-]?\s*(\d)\b', caseSensitive: false),
    ];

    for (final pattern in labelBeforeValuePatterns) {
      final match = pattern.firstMatch(block);
      if (match == null) continue;
      final value = int.tryParse(match.group(1) ?? '');
      if (_isValidSuperNumber(value)) return value;
    }

    // Einige Quellen, z. B. lotto.net, liefern die Superzahl als siebte Kugel
    // direkt nach den sechs Hauptzahlen und schreiben danach nur "Super".
    // Beispiel: 2 6 8 11 14 39 7 Super.
    final valueBeforeSuper = RegExp(
      r'(?:^|[^\d])(\d)(?!\d)\s*(?:Superzahl|Super)(?!\s*6\b)',
      caseSensitive: false,
    ).firstMatch(block);
    if (valueBeforeSuper != null) {
      final value = int.tryParse(valueBeforeSuper.group(1) ?? '');
      if (_isValidSuperNumber(value)) return value;
    }

    final sequenceValue = _extractSuperNumberFromNumberSequence(
      block,
      mainNumbers: mainNumbers,
    );
    if (_isValidSuperNumber(sequenceValue)) return sequenceValue;

    return null;
  }

  int? _extractSuperNumberFromNumberSequence(
    String block, {
    required List<int> mainNumbers,
  }) {
    final stopMatch = RegExp(
      r'\b(?:Jackpot|Gewinnquote|Gewinnquoten|Quote|Quoten|Spiel\s*77|Spiel77|Super\s*6|Super6)\b',
      caseSensitive: false,
    ).firstMatch(block);
    final relevant = stopMatch == null ? block : block.substring(0, stopMatch.start);

    final values = RegExp(r'\b(\d{1,2})\b')
        .allMatches(relevant)
        .map((m) => int.tryParse(m.group(1) ?? ''))
        .whereType<int>()
        .toList();

    if (values.length < 7) return null;

    final expectedMain = _normalizeMainNumbers(mainNumbers);
    for (var start = 0; start <= values.length - 7; start++) {
      final firstSix = _normalizeMainNumbers(values.sublist(start, start + 6));
      final possibleSuper = values[start + 6];
      if (firstSix.length == 6 &&
          _sameIntList(firstSix, expectedMain) &&
          possibleSuper >= 0 &&
          possibleSuper <= 9) {
        return possibleSuper;
      }
    }

    return null;
  }

  bool _isValidSuperNumber(int? value) {
    return value != null && value >= 0 && value <= 9;
  }

  bool _sameIntList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String? _extractSpiel77(String block) {
    return _extractDigitGame(block, labels: const ['Spiel 77', 'Spiel77'], length: 7);
  }

  String? _extractSuper6(String block) {
    return _extractDigitGame(block, labels: const ['Super 6', 'SUPER 6', 'Super6', 'SUPER6'], length: 6);
  }

  String? _extractDigitGame(
      String block, {
        required List<String> labels,
        required int length,
      }) {
    for (final label in labels) {
      final labelPattern = RegExp.escape(label).replaceAll(r'\ ', r'\s*');
      final match = RegExp(
        '$labelPattern\\s*[:\\-]?\\s*([0-9](?:\\s*[0-9]){${length - 1}})',
        caseSensitive: false,
      ).firstMatch(block);

      if (match == null) continue;
      final digits = (match.group(1) ?? '').replaceAll(RegExp(r'\D'), '');
      final normalized = _normalizeDigitGame(digits, length);
      if (normalized != null) return normalized;
    }
    return null;
  }

  List<int> _normalizeMainNumbers(List<int> input) {
    final clean = input.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
    return clean.length == 6 ? clean : const [];
  }

  int? _normalizeSuperNumber(int? value) {
    if (value == null) return null;
    if (value < 0 || value > 9) return null;
    return value;
  }

  String? _normalizeDigitGame(String? value, int length) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != length) return null;
    return digits;
  }

  bool _isValidDrawDay(DateTime date) {
    return date.weekday == DateTime.wednesday || date.weekday == DateTime.saturday;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _buildStableId(DateTime date, List<int> numbers) {
    return '${date.toIso8601String()}-${numbers.join('-')}';
  }

  String _htmlToPlainText(String html) {
    var text = html;

    text = text.replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');

    text = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(?:div|p|li|tr|td|th|h1|h2|h3|h4|section|article)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ');

    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&auml;', 'ä')
        .replaceAll('&Uuml;', 'Ü')
        .replaceAll('&Ouml;', 'Ö')
        .replaceAll('&Auml;', 'Ä')
        .replaceAll('&szlig;', 'ß')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n')
        .trim();
  }

  int? _monthFromEnglish(String name) {
    switch (name.toLowerCase()) {
      case 'january':
        return 1;
      case 'february':
        return 2;
      case 'march':
        return 3;
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'june':
        return 6;
      case 'july':
        return 7;
      case 'august':
        return 8;
      case 'september':
        return 9;
      case 'october':
        return 10;
      case 'november':
        return 11;
      case 'december':
        return 12;
      default:
        return null;
    }
  }
}

class _DrawHeading {
  const _DrawHeading(this.start, this.end, this.drawDate);

  final int start;
  final int end;
  final DateTime drawDate;
}
