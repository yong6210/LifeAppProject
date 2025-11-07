import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/cross_domain_analytics_provider.dart';
import 'package:life_app/services/analytics/cross_domain_analytics_service.dart';

class CrossDomainAnalyticsExporter {
  Future<String> exportToPdf({
    required CrossDomainAnalytics analytics,
    required CrossDomainRange range,
    required AppLocalizations l10n,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat.yMMMd(l10n.locale.toLanguageTag());
    final timeFormat = DateFormat.Hm(l10n.locale.toLanguageTag());
    final fileTimestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final rangeLabel = _rangeLabel(range, l10n);
    final averageMood = analytics.averageMoodScore != null
        ? NumberFormat.percentPattern(
            l10n.locale.toLanguageTag(),
          ).format(analytics.averageMoodScore)
        : '—';

    final correlationRows = [
      [
        l10n.tr('analytics_dashboard_correlation_focus_sleep'),
        _formatCorrelation(analytics.focusSleepCorrelation),
        _describeCorrelation(analytics.focusSleepCorrelation, l10n),
      ],
      [
        l10n.tr('analytics_dashboard_correlation_sleep_mood'),
        _formatCorrelation(analytics.sleepMoodCorrelation),
        _describeCorrelation(analytics.sleepMoodCorrelation, l10n),
      ],
      [
        l10n.tr('analytics_dashboard_correlation_focus_mood'),
        _formatCorrelation(analytics.focusMoodCorrelation),
        _describeCorrelation(analytics.focusMoodCorrelation, l10n),
      ],
    ];

    final points = analytics.points;
    final tableRows = points
        .map(
          (point) => [
            dateFormat.format(point.date),
            point.focusMinutes.toString(),
            point.sleepMinutes.toString(),
            point.moodScore == null
                ? '—'
                : NumberFormat.percentPattern(
                    l10n.locale.toLanguageTag(),
                  ).format(point.moodScore),
            point.journalSleepHours == null
                ? '—'
                : point.journalSleepHours!.toStringAsFixed(1),
          ],
        )
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        build: (context) => [
          pw.Text(
            l10n.tr('analytics_dashboard_title'),
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            l10n.tr('analytics_dashboard_pdf_generated_on', {
              'date': '${dateFormat.format(now)} ${timeFormat.format(now)}',
            }),
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            '${l10n.tr('analytics_dashboard_range_label')}: $rangeLabel',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerAlignment: pw.Alignment.centerLeft,
            headers: [
              l10n.tr('analytics_dashboard_avg_focus'),
              l10n.tr('analytics_dashboard_avg_sleep'),
              l10n.tr('analytics_dashboard_avg_mood'),
              l10n.tr('analytics_dashboard_sleep_debt'),
            ],
            data: [
              [
                '${analytics.averageFocusMinutes.toStringAsFixed(0)} min',
                '${analytics.averageSleepMinutes.toStringAsFixed(0)} min',
                averageMood,
                l10n.tr('analytics_dashboard_sleep_debt_hours', {
                  'hours': (analytics.totalSleepDebtMinutes / 60)
                      .clamp(0, double.infinity)
                      .toStringAsFixed(1),
                }),
              ],
            ],
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            l10n.tr('analytics_dashboard_pdf_correlations_heading'),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: [
              l10n.tr('analytics_dashboard_pdf_metric'),
              l10n.tr('analytics_dashboard_pdf_coefficient'),
              l10n.tr('analytics_dashboard_pdf_interpretation'),
            ],
            data: correlationRows,
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerAlignment: pw.Alignment.centerLeft,
            headers: [
              l10n.tr('analytics_dashboard_highlight_focus'),
              l10n.tr('analytics_dashboard_highlight_sleep'),
              l10n.tr('analytics_dashboard_highlight_mood'),
            ],
            data: [
              [
                _formatHighlight(
                  analytics.highlights.bestFocusDate,
                  dateFormat,
                ),
                _formatHighlight(
                  analytics.highlights.bestSleepDate,
                  dateFormat,
                ),
                _formatHighlight(analytics.highlights.lowMoodDate, dateFormat),
              ],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            l10n.tr('analytics_dashboard_table_header_date'),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              l10n.tr('analytics_dashboard_table_header_date'),
              l10n.tr('analytics_dashboard_table_header_focus'),
              l10n.tr('analytics_dashboard_table_header_sleep'),
              l10n.tr('analytics_dashboard_table_header_mood'),
              l10n.tr('analytics_dashboard_table_header_journal_sleep'),
            ],
            data: tableRows,
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, 'cross_domain_$fileTimestamp.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  String _rangeLabel(CrossDomainRange range, AppLocalizations l10n) {
    switch (range) {
      case CrossDomainRange.last7Days:
        return l10n.tr('analytics_dashboard_range_7');
      case CrossDomainRange.last14Days:
        return l10n.tr('analytics_dashboard_range_14');
      case CrossDomainRange.last30Days:
        return l10n.tr('analytics_dashboard_range_30');
    }
  }

  String _formatCorrelation(double? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(2);
  }

  String _describeCorrelation(double? value, AppLocalizations l10n) {
    if (value == null) {
      return l10n.tr('analytics_dashboard_correlation_neutral');
    }
    if (value >= 0.35) {
      return l10n.tr('analytics_dashboard_correlation_positive');
    }
    if (value <= -0.35) {
      return l10n.tr('analytics_dashboard_correlation_negative');
    }
    return l10n.tr('analytics_dashboard_correlation_neutral');
  }

  String _formatHighlight(DateTime? date, DateFormat formatter) {
    if (date == null) {
      return '—';
    }
    return formatter.format(date);
  }
}
