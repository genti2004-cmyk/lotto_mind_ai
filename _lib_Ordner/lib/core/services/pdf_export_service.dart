import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Lotto Mind AI - PDF Export Service PRO
///
/// Enthält robuste Premium-PDFs für:
/// 1) Analysebericht
/// 2) Spielschein/Systembericht
/// 3) Gewinn-/ROI-Bericht
///
/// Branding bleibt ausschließlich: Lotto Mind AI.
class PdfExportService {
  static const String _appName = 'Lotto Mind AI';
  static const PdfColor _ink = PdfColors.blueGrey900;
  static const PdfColor _muted = PdfColors.blueGrey600;
  static const PdfColor _line = PdfColors.blueGrey200;
  static const PdfColor _soft = PdfColors.blueGrey50;
  static const PdfColor _accent = PdfColors.indigo700;

  // ---------------------------------------------------------------------------
  // 1) ANALYSE PDF
  // ---------------------------------------------------------------------------

  static Future<Uint8List> buildAnalysisPdfBytes({
    required List<int> numbers,
    required String systemType,
    required String profile,
    required String drawDay,
    required int drawCount,
    required double roi,
    String title = 'Analyse Bericht',
    String? strategyLabel,
    String? reasoning,
  }) async {
    final pdf = pw.Document();
    final cleanNumbers = _cleanNumbers(numbers);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(26, 24, 26, 24),
        footer: (context) => _footer(context),
        build: (context) {
          return [
            _header(title, subtitle: 'Premium Analyse Export'),
            pw.SizedBox(height: 16),
            _summaryCards([
              _PdfKpi('System', systemType),
              _PdfKpi('Profil', profile),
              _PdfKpi('Ziehungstag', drawDay),
              _PdfKpi('Ziehungen', '$drawCount'),
            ]),
            pw.SizedBox(height: 16),
            _sectionTitle('Empfohlene Zahlen'),
            _numberPanel(cleanNumbers),
            pw.SizedBox(height: 14),
            _sectionTitle('Analyse Details'),
            _infoTable([
              ['System / Modus', systemType],
              ['Analyseprofil', profile],
              ['Ziehungstag', drawDay],
              ['Analyse-Ziehungen', '$drawCount'],
              if (strategyLabel != null && strategyLabel.trim().isNotEmpty)
                ['Strategie', strategyLabel.trim()],
              ['ROI Modell', _percent(roi)],
              ['Bewertung', _roiLabel(roi)],
            ]),
            if (reasoning != null && reasoning.trim().isNotEmpty) ...[
              pw.SizedBox(height: 16),
              _sectionTitle('AI Begründung'),
              _textBox(reasoning.trim()),
            ],
            pw.SizedBox(height: 16),
            _sectionTitle('Interpretation'),
            _textBox(
              'Dieser Bericht zeigt die aktuell berechnete Zahlenempfehlung. '
                  'Die Werte sind Modellwerte und dienen zum Vergleich von Strategien, '
                  'nicht als Gewinnzusage.',
            ),
            pw.SizedBox(height: 18),
            _disclaimer(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printAnalysisPdf({
    required List<int> numbers,
    required String systemType,
    required String profile,
    required String drawDay,
    required int drawCount,
    required double roi,
    String title = 'Analyse Bericht',
    String? strategyLabel,
    String? reasoning,
  }) async {
    final bytes = await buildAnalysisPdfBytes(
      numbers: numbers,
      systemType: systemType,
      profile: profile,
      drawDay: drawDay,
      drawCount: drawCount,
      roi: roi,
      title: title,
      strategyLabel: strategyLabel,
      reasoning: reasoning,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Kompatibilitäts-Alias für ältere Buttons.
  static Future<void> generateAnalysisPdf({
    required List<int> numbers,
    required String systemType,
    required String profile,
    required String drawDay,
    required int drawCount,
    required double roi,
    String title = 'Analyse Bericht',
    String? strategyLabel,
    String? reasoning,
  }) async {
    await printAnalysisPdf(
      numbers: numbers,
      systemType: systemType,
      profile: profile,
      drawDay: drawDay,
      drawCount: drawCount,
      roi: roi,
      title: title,
      strategyLabel: strategyLabel,
      reasoning: reasoning,
    );
  }

  // ---------------------------------------------------------------------------
  // 2) SPIELSCHEIN / SYSTEM PDF
  // ---------------------------------------------------------------------------

  static Future<Uint8List> buildTicketPdfBytes({
    required String systemType,
    required List<int> basisNumbers,
    required List<List<int>> rows,
    required int superNumber,
    required String spiel77,
    required String super6,
    required double stake,
    required String drawDay,
    DateTime? createdAt,
    String title = 'Spielschein Export',
  }) async {
    final pdf = pw.Document();
    final created = createdAt ?? DateTime.now();
    final cleanBasis = _cleanNumbers(basisNumbers);
    final cleanRows = _cleanRows(rows);
    final costPerRow = cleanRows.isEmpty ? 0.0 : stake / cleanRows.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 24),
        footer: (context) => _footer(context),
        build: (context) {
          return [
            _header(title, subtitle: 'Systemschein / Tipp Export'),
            pw.SizedBox(height: 14),
            _summaryCards([
              _PdfKpi('System', systemType),
              _PdfKpi('Reihen', '${cleanRows.length}'),
              _PdfKpi('Basiszahlen', '${cleanBasis.length}'),
              _PdfKpi('Einsatz', _money(stake)),
            ]),
            pw.SizedBox(height: 14),
            _sectionTitle('Spielschein Übersicht'),
            _infoTable([
              ['System', systemType],
              ['Ziehungstag', drawDay],
              ['Erstellt am', _formatDate(created)],
              ['Basiszahlen', '${cleanBasis.length}'],
              ['Spielreihen', '${cleanRows.length}'],
              ['Kosten je Reihe Modell', _money(costPerRow)],
              ['Einsatz Modell', _money(stake)],
            ]),
            pw.SizedBox(height: 14),
            _sectionTitle('Basiszahlen'),
            _numberPanel(cleanBasis),
            pw.SizedBox(height: 14),
            _sectionTitle('Zusatzspiele / Losnummer'),
            _infoTable([
              ['Superzahl', '$superNumber'],
              ['Spiel 77', spiel77.trim().isEmpty ? '-' : spiel77.trim()],
              ['Super 6', super6.trim().isEmpty ? '-' : super6.trim()],
            ]),
            pw.SizedBox(height: 16),
            _sectionTitle('Spielreihen'),
            _rowsTable(cleanRows),
            pw.SizedBox(height: 16),
            _disclaimer(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printTicketPdf({
    required String systemType,
    required List<int> basisNumbers,
    required List<List<int>> rows,
    required int superNumber,
    required String spiel77,
    required String super6,
    required double stake,
    required String drawDay,
    DateTime? createdAt,
    String title = 'Spielschein Export',
  }) async {
    final bytes = await buildTicketPdfBytes(
      systemType: systemType,
      basisNumbers: basisNumbers,
      rows: rows,
      superNumber: superNumber,
      spiel77: spiel77,
      super6: super6,
      stake: stake,
      drawDay: drawDay,
      createdAt: createdAt,
      title: title,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ---------------------------------------------------------------------------
  // 3) GEWINN / ROI PDF
  // ---------------------------------------------------------------------------

  static Future<Uint8List> buildResultPdfBytes({
    required String systemType,
    required List<int> drawNumbers,
    required int? drawSuperNumber,
    required List<PdfResultRow> resultRows,
    required double stake,
    required double grossReturn,
    required double netReturn,
    required double roi,
    required String drawDateLabel,
    String title = 'Gewinn- und ROI Bericht',
  }) async {
    final pdf = pw.Document();
    final cleanDrawNumbers = _cleanNumbers(drawNumbers);
    final cleanResultRows = resultRows.where((row) => row.numbers.isNotEmpty).toList();
    final bestHit = cleanResultRows.isEmpty
        ? 0
        : cleanResultRows.map((r) => r.hits).reduce((a, b) => a > b ? a : b);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 24),
        footer: (context) => _footer(context),
        build: (context) {
          return [
            _header(title, subtitle: 'Gewinnbewertung / Rücktest'),
            pw.SizedBox(height: 14),
            _summaryCards([
              _PdfKpi('System', systemType),
              _PdfKpi('Reihen', '${cleanResultRows.length}'),
              _PdfKpi('Bester Treffer', '$bestHit'),
              _PdfKpi('ROI', _percent(roi)),
            ]),
            pw.SizedBox(height: 14),
            _sectionTitle('Gezogene Zahlen'),
            _infoTable([
              ['Ziehung', drawDateLabel],
              ['System', systemType],
              ['Superzahl', drawSuperNumber == null ? '-' : '$drawSuperNumber'],
            ]),
            pw.SizedBox(height: 10),
            _numberPanel(cleanDrawNumbers),
            pw.SizedBox(height: 16),
            _sectionTitle('Gewinnbewertung'),
            _infoTable([
              ['Einsatz Modell', _money(stake)],
              ['Brutto Modell', _money(grossReturn)],
              ['Netto Modell', _money(netReturn)],
              ['ROI Modell', _percent(roi)],
              ['Bewertung', _roiLabel(roi)],
            ]),
            pw.SizedBox(height: 16),
            _sectionTitle('Treffer je Reihe'),
            _resultRowsTable(cleanResultRows),
            pw.SizedBox(height: 16),
            _disclaimer(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printResultPdf({
    required String systemType,
    required List<int> drawNumbers,
    required int? drawSuperNumber,
    required List<PdfResultRow> resultRows,
    required double stake,
    required double grossReturn,
    required double netReturn,
    required double roi,
    required String drawDateLabel,
    String title = 'Gewinn- und ROI Bericht',
  }) async {
    final bytes = await buildResultPdfBytes(
      systemType: systemType,
      drawNumbers: drawNumbers,
      drawSuperNumber: drawSuperNumber,
      resultRows: resultRows,
      stake: stake,
      grossReturn: grossReturn,
      netReturn: netReturn,
      roi: roi,
      drawDateLabel: drawDateLabel,
      title: title,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ---------------------------------------------------------------------------
  // Factory für Result-Zeilen
  // ---------------------------------------------------------------------------

  static PdfResultRow resultRow({
    required int index,
    required List<int> numbers,
    required int hits,
    required bool superNumberHit,
    required String winClass,
    required double modelValue,
  }) {
    return PdfResultRow(
      index: index,
      numbers: _cleanNumbers(numbers),
      hits: hits,
      superNumberHit: superNumberHit,
      winClass: winClass,
      modelValue: modelValue,
    );
  }

  // ---------------------------------------------------------------------------
  // PDF Widgets
  // ---------------------------------------------------------------------------

  static pw.Widget _header(String title, {required String subtitle}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _ink,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 38,
                height: 38,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColors.white,
                ),
                child: pw.Text(
                  'AI',
                  style: pw.TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _appName,
                    style: pw.TextStyle(
                      fontSize: 21,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: PdfColors.blueGrey100,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Container(
            constraints: const pw.BoxConstraints(maxWidth: 170),
            child: pw.Text(
              title,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryCards(List<_PdfKpi> cards) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: cards.map((card) {
        return pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 7),
            padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 10),
            decoration: pw.BoxDecoration(
              color: _soft,
              border: pw.Border.all(color: _line, width: 0.7),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  card.label,
                  maxLines: 1,
                  style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  card.value,
                  maxLines: 2,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        children: [
          pw.Container(width: 4, height: 14, color: _accent),
          pw.SizedBox(width: 7),
          pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 14.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.15),
        1: pw.FlexColumnWidth(2.25),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            _cell(row.isNotEmpty ? row[0] : '', bold: true, background: _soft),
            _cell(row.length > 1 ? row[1] : ''),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _numberPanel(List<int> numbers) {
    if (numbers.isEmpty) {
      return _textBox('Keine Zahlen vorhanden.');
    }
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: numbers.map(_numberBubble).toList(),
      ),
    );
  }

  static pw.Widget _rowsTable(List<List<int>> rows) {
    if (rows.isEmpty) return _textBox('Keine Spielreihen vorhanden.');
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(42),
        1: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: [
            _cell('Reihe', bold: true),
            _cell('Zahlen', bold: true),
          ],
        ),
        ...rows.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final numbers = _cleanNumbers(entry.value);
          return pw.TableRow(
            children: [
              _cell('$index'),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: numbers.map(_numberBubbleSmall).toList(),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _resultRowsTable(List<PdfResultRow> rows) {
    if (rows.isEmpty) return _textBox('Keine Ergebniszeilen vorhanden.');
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(32),
        1: pw.FlexColumnWidth(2.35),
        2: pw.FixedColumnWidth(45),
        3: pw.FixedColumnWidth(38),
        4: pw.FixedColumnWidth(70),
        5: pw.FixedColumnWidth(62),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: [
            _cell('#', bold: true),
            _cell('Zahlen', bold: true),
            _cell('Treffer', bold: true),
            _cell('SZ', bold: true),
            _cell('Klasse', bold: true),
            _cell('Wert', bold: true),
          ],
        ),
        ...rows.map((row) {
          final numbers = _cleanNumbers(row.numbers);
          return pw.TableRow(
            children: [
              _cell('${row.index}'),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: numbers.map(_numberBubbleTiny).toList(),
                ),
              ),
              _cell('${row.hits}'),
              _cell(row.superNumberHit ? 'Ja' : 'Nein'),
              _cell(row.winClass),
              _cell(_money(row.modelValue)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(
      String text, {
        bool bold = false,
        PdfColor? background,
      }) {
    final child = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        maxLines: 4,
        style: pw.TextStyle(
          fontSize: 9.2,
          color: _ink,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );

    if (background == null) return child;
    return pw.Container(color: background, child: child);
  }

  static pw.Widget _numberBubble(int number) {
    return pw.Container(
      width: 32,
      height: 32,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: PdfColors.indigo50,
        border: pw.Border.all(color: _accent, width: 1),
      ),
      child: pw.Text(
        '$number',
        style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: _ink),
      ),
    );
  }

  static pw.Widget _numberBubbleSmall(int number) {
    return pw.Container(
      width: 24,
      height: 24,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _accent, width: 0.75),
      ),
      child: pw.Text('$number', style: const pw.TextStyle(fontSize: 8.2, color: _ink)),
    );
  }

  static pw.Widget _numberBubbleTiny(int number) {
    return pw.Container(
      width: 19,
      height: 19,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: PdfColors.blueGrey500, width: 0.55),
      ),
      child: pw.Text('$number', style: const pw.TextStyle(fontSize: 7.2, color: _ink)),
    );
  }

  static pw.Widget _textBox(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: _soft,
        border: pw.Border.all(color: _line, width: 0.6),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.5, height: 1.35, color: _ink)),
    );
  }

  static pw.Widget _disclaimer() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber200, width: 0.7),
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Text(
        'Hinweis: Lotto Mind AI erstellt Analyse- und Modellberichte. '
            'Die Ergebnisse sind keine Gewinnzusage und ersetzen keine offiziellen Gewinnquoten, Spielregeln oder verantwortungsbewusste Budgetgrenzen.',
        style: const pw.TextStyle(fontSize: 8.4, color: PdfColors.blueGrey800, height: 1.25),
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Erstellt mit $_appName',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.Text(
            'Seite ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static List<int> _cleanNumbers(List<int> numbers) {
    final clean = numbers.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
    return clean;
  }

  static List<List<int>> _cleanRows(List<List<int>> rows) {
    return rows
        .map(_cleanNumbers)
        .where((row) => row.isNotEmpty)
        .toList();
  }

  static String _money(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  static String _percent(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} %';
  }

  static String _roiLabel(double roi) {
    if (roi >= 0) return 'Überdurchschnittlich im Modell';
    if (roi >= -35) return 'Stark im Modell';
    if (roi >= -65) return 'Ausgewogen';
    if (roi >= -90) return 'Hoher Einsatz / niedrigere Effizienz';
    return 'Sehr defensiv bewerten';
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }
}

class PdfResultRow {
  final int index;
  final List<int> numbers;
  final int hits;
  final bool superNumberHit;
  final String winClass;
  final double modelValue;

  const PdfResultRow({
    required this.index,
    required this.numbers,
    required this.hits,
    required this.superNumberHit,
    required this.winClass,
    required this.modelValue,
  });
}

class _PdfKpi {
  final String label;
  final String value;

  const _PdfKpi(this.label, this.value);
}
