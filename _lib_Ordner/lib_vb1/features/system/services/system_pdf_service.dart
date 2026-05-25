import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/system_price_breakdown.dart';
import '../domain/system_ticket.dart';
import '../domain/vew_system_type.dart';

class SystemPdfService {
  SystemPdfService();

  Future<File> generateTicketPdf({
    required SystemTicket ticket,
    required SystemPriceBreakdown price,
    required bool withSpiel77,
    required bool withSuper6,
    required bool playWednesday,
    required bool playSaturday,
    required int weeks,
  }) async {
    final pdf = pw.Document();
    final sheets = _splitIntoSheets(ticket.rows);

    for (int pageIndex = 0; pageIndex < sheets.length; pageIndex++) {
      final sheetRows = sheets[pageIndex];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 28),
          build: (context) => [
            _buildHeader(
              ticket: ticket,
              pageIndex: pageIndex,
              pageCount: sheets.length,
            ),
            pw.SizedBox(height: 14),
            _buildSubmissionInfo(
              ticket: ticket,
              withSpiel77: withSpiel77,
              withSuper6: withSuper6,
              playWednesday: playWednesday,
              playSaturday: playSaturday,
              weeks: weeks,
            ),
            pw.SizedBox(height: 14),
            _buildPriceBlock(price),
            pw.SizedBox(height: 16),
            _buildBaseNumbersBlock(ticket.baseNumbers),
            pw.SizedBox(height: 16),
            _buildRowsSection(sheetRows),
            pw.SizedBox(height: 18),
            _buildFooterNote(),
          ],
        ),
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${directory.path}/LottoMindAI_Systemschein_$timestamp.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  List<List<List<int>>> _splitIntoSheets(List<List<int>> rows) {
    final sheets = <List<List<int>>>[];

    for (int i = 0; i < rows.length; i += 12) {
      sheets.add(
        rows.sublist(
          i,
          (i + 12 > rows.length) ? rows.length : i + 12,
        ),
      );
    }

    return sheets;
  }

  pw.Widget _buildHeader({
    required SystemTicket ticket,
    required int pageIndex,
    required int pageCount,
  }) {
    final modeLabel =
    ticket.mode.name == 'full' ? 'Vollsystem' : _vewLabel(ticket.vewType);

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
        gradient: const pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [
            PdfColor.fromInt(0xFF0D47A1),
            PdfColor.fromInt(0xFF1565C0),
          ],
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0x2EFFFFFF),
                  borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(999)),
                ),
                child: pw.Text(
                  'LottoMind AI PDF',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                'Seite ${pageIndex + 1} / $pageCount',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'LOTTO 6aus49',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Systemschein · $modeLabel',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Reihen gesamt: ${ticket.rowCount} · Basiszahlen: ${ticket.baseNumbers.join(' · ')}',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSubmissionInfo({
    required SystemTicket ticket,
    required bool withSpiel77,
    required bool withSuper6,
    required bool playWednesday,
    required bool playSaturday,
    required int weeks,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _infoCard(
            title: 'Abgabe',
            rows: [
              _labelValue('Mittwoch', playWednesday ? 'Ja' : 'Nein'),
              _labelValue('Samstag', playSaturday ? 'Ja' : 'Nein'),
              _labelValue('Wochen', '$weeks'),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _infoCard(
            title: 'Zusatzlotterien',
            rows: [
              _labelValue('Spiel 77', withSpiel77 ? 'Aktiv' : 'Aus'),
              _labelValue('SUPER 6', withSuper6 ? 'Aktiv' : 'Aus'),
              _labelValue('Superzahl', 'Automatisch'),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _infoCard(
            title: 'System',
            rows: [
              _labelValue(
                'Modus',
                ticket.mode.name == 'full'
                    ? 'Vollsystem'
                    : _vewLabel(ticket.vewType),
              ),
              _labelValue('Reihen', '${ticket.rowCount}'),
              _labelValue(
                'Intervall Typ',
                ticket.vewType == null
                    ? '-'
                    : '${ticket.vewType!.selectedCount}/${ticket.vewType!.guaranteeHits}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _infoCard({
    required String title,
    required List<pw.Widget> rows,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF7F9FC),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE1E8F0),
          width: 0.8,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF0D47A1),
            ),
          ),
          pw.SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromInt(0xFF607080),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPriceBlock(SystemPriceBreakdown price) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFFFFF),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFD8E2EE),
          width: 0.9,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Preisübersicht',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF0D47A1),
            ),
          ),
          pw.SizedBox(height: 10),
          _priceLine('LOTTO', _formatEuro(price.lotto)),
          _priceLine('Spiel 77', _formatEuro(price.spiel77)),
          _priceLine('SUPER 6', _formatEuro(price.super6)),
          _priceLine('Bearbeitungsgebühr', _formatEuro(price.processingFee)),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Container(
              height: 1,
              color: PdfColor.fromInt(0xFFD8E2EE),
            ),
          ),
          _priceLine('Gesamt', _formatEuro(price.total), bold: true),
        ],
      ),
    );
  }

  pw.Widget _priceLine(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: bold ? 11 : 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: bold ? PdfColor.fromInt(0xFF0D47A1) : PdfColors.black,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(label, style: style),
          ),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  pw.Widget _buildBaseNumbersBlock(List<int> baseNumbers) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFFFFF),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFD8E2EE),
          width: 0.9,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Basisauswahl',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF0D47A1),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(49, (index) {
              final number = index + 1;
              final selected = baseNumbers.contains(number);

              return pw.Container(
                width: 22,
                height: 22,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: selected
                      ? PdfColor.fromInt(0xFF1565C0)
                      : PdfColors.white,
                  border: pw.Border.all(
                    color: selected
                        ? PdfColor.fromInt(0xFF1565C0)
                        : PdfColor.fromInt(0xFFB8C5D3),
                    width: 0.7,
                  ),
                  borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  '$number',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: selected ? PdfColors.white : PdfColors.black,
                    fontWeight: selected
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRowsSection(List<List<int>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Spielreihen (max. 12 pro Schein)',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF0D47A1),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColor.fromInt(0xFFB8C5D3),
            width: 0.6,
          ),
          columnWidths: {
            0: const pw.FixedColumnWidth(24),
            1: const pw.FixedColumnWidth(18),
            2: const pw.FlexColumnWidth(),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1F5FA),
              ),
              children: [
                _tableHeaderCell('Nr.'),
                _tableHeaderCell('□'),
                _tableHeaderCell('Zahlen'),
              ],
            ),
            ...List.generate(rows.length, (index) {
              final row = rows[index];

              return pw.TableRow(
                children: [
                  pw.Container(
                    height: 24,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '${index + 1}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Container(
                    height: 24,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '□',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 6,
                    ),
                    child: pw.Text(
                      row.map((n) => n.toString().padLeft(2, ' ')).join('   '),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF0D47A1),
        ),
      ),
    );
  }

  pw.Widget _buildFooterNote() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF7F9FC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(
        'Hinweis: Dieses PDF wurde in LottoMind AI erzeugt. '
            'Es dient als übersichtliche Abgabe- und Prüfunterlage für deine gewählten Systemreihen. '
            'Es ist kein offizieller Spielschein eines Lotterieanbieters. '
            'Verbindlich ist ausschließlich die tatsächliche Spielquittung der offiziellen Annahmestelle bzw. des offiziellen Anbieters.',
        style: pw.TextStyle(
          fontSize: 8.8,
          color: PdfColor.fromInt(0xFF5F6E7A),
        ),
      ),
    );
  }

  String _formatEuro(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  String _vewLabel(VewSystemType? type) {
    if (type == null) return 'Intervall';

    switch (type) {
      case VewSystemType.vew3:
        return 'Intervall 3';
      case VewSystemType.vew4:
        return 'Intervall 4';
      case VewSystemType.vew5:
        return 'Intervall 5';
      case VewSystemType.vew6:
        return 'Intervall 6';
      case VewSystemType.vew7_3:
        return 'Intervall 7-3';
      case VewSystemType.vew8_4:
        return 'Intervall 8-4';
      case VewSystemType.vew9_4:
        return 'Intervall 9-4';
      case VewSystemType.vew9_5:
        return 'Intervall 9-5';
      case VewSystemType.vew10_5:
        return 'Intervall 10-5';
    }
  }
}