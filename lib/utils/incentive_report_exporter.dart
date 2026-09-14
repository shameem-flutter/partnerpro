import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../models/admin_models.dart';
import 'currency_utils.dart';

/// PDF Report Generator for Incentive Reports
class PdfReportGenerator {
  static Future<Uint8List> generateIncentiveReport({
    required List<SalesReportEntry> entries,
    required SalesReportResponse reportData,
    required String targetCurrency,
  }) async {
    final pdf = pw.Document();

    final convertedTotalDebit = CurrencyUtils.convertAmount(
      reportData.totalDebit,
      'AED',
      targetCurrency,
    );
    final convertedTotalCredit = CurrencyUtils.convertAmount(
      reportData.totalCommission,
      'AED',
      targetCurrency,
    );
    final convertedTotalBalance = CurrencyUtils.convertAmount(
      reportData.totalAmount,
      'AED',
      targetCurrency,
    );

    // Color Palette
    final primaryColor = PdfColor.fromHex('#032267');
    final creditGreen = PdfColor.fromHex('#2E7D32');
    final debitRed = PdfColor.fromHex('#C62828');
    final balanceBlue = PdfColor.fromHex('#032267');
    final lightBg = PdfColor.fromHex('#F8F9FB');
    final borderColor = PdfColor.fromHex('#D3D3D3');
    final textDark = PdfColor.fromHex('#1F2937');
    final textMuted = PdfColor.fromHex('#6B7280');

    final nowFormatted = _formatDateTime(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Banner
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SAASORDER - PARTNERPRO',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'INCENTIVE REPORT',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Generated On: $nowFormatted',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Currency: $targetCurrency',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'PartnerPro Incentive Report - Confidential',
                  style: pw.TextStyle(color: textMuted, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    color: textMuted,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // Summary KPI Cards
          pw.Row(
            children: [
              _buildSummaryCard(
                title: 'Total Credit',
                amount:
                    '$targetCurrency ${convertedTotalCredit.toStringAsFixed(2)}',
                color: creditGreen,
                bgTint: PdfColor.fromHex('#E8F5E9'),
              ),
              pw.SizedBox(width: 12),
              _buildSummaryCard(
                title: 'Total Debit',
                amount:
                    '$targetCurrency ${convertedTotalDebit.toStringAsFixed(2)}',
                color: debitRed,
                bgTint: PdfColor.fromHex('#FFEBEE'),
              ),
              pw.SizedBox(width: 12),
              _buildSummaryCard(
                title: 'Closing Balance',
                amount:
                    '$targetCurrency ${convertedTotalBalance.toStringAsFixed(2)}',
                color: balanceBlue,
                bgTint: PdfColor.fromHex('#E3F2FD'),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Table of Entries
          _buildEntriesTable(
            entries: entries,
            targetCurrency: targetCurrency,
            primaryColor: primaryColor,
            lightBg: lightBg,
            borderColor: borderColor,
            textDark: textDark,
            convertedTotalCredit: convertedTotalCredit,
            convertedTotalDebit: convertedTotalDebit,
            convertedTotalBalance: convertedTotalBalance,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryCard({
    required String title,
    required String amount,
    required PdfColor color,
    required PdfColor bgTint,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: bgTint,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              amount,
              style: pw.TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildEntriesTable({
    required List<SalesReportEntry> entries,
    required String targetCurrency,
    required PdfColor primaryColor,
    required PdfColor lightBg,
    required PdfColor borderColor,
    required PdfColor textDark,
    required double convertedTotalCredit,
    required double convertedTotalDebit,
    required double convertedTotalBalance,
  }) {
    final headers = [
      'Approved At',
      'Invoice Ref',
      'Customer Name',
      'Currency',
      'Debit',
      'Credit',
      'Balance',
    ];

    final tableRows = <pw.TableRow>[];

    // Header Row
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: primaryColor),
        children: headers.map((h) {
          final isNumeric = h == 'Debit' || h == 'Credit' || h == 'Balance';
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            alignment: isNumeric
                ? pw.Alignment.centerRight
                : (h == 'Approved At' || h == 'Currency')
                    ? pw.Alignment.center
                    : pw.Alignment.centerLeft,
            child: pw.Text(
              h,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );

    // Data Rows
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isEven = i % 2 == 1;
      final rowBg = isEven ? lightBg : PdfColors.white;

      final convertedDebit = CurrencyUtils.convertAmount(
        entry.debit,
        'AED',
        targetCurrency,
      );
      final convertedCredit = CurrencyUtils.convertAmount(
        entry.commissionAmount,
        'AED',
        targetCurrency,
      );
      final convertedBalance = CurrencyUtils.convertAmount(
        entry.balance,
        'AED',
        targetCurrency,
      );

      String formattedDate = '';
      final parsedDate = DateTime.tryParse(entry.approvedAt);
      if (parsedDate != null) {
        formattedDate = _formatDate(parsedDate);
      } else if (entry.approvedAt.isNotEmpty &&
          entry.approvedAt != 'null' &&
          entry.approvedAt != 'False') {
        formattedDate = entry.approvedAt;
      }

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: rowBg,
            border: pw.Border(
              bottom: pw.BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          children: [
            // Approved At
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text(
                formattedDate,
                style: pw.TextStyle(fontSize: 8.5, color: textDark),
              ),
            ),
            // Invoice Ref
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                entry.invoiceReferenceNo,
                style: pw.TextStyle(fontSize: 8.5, color: textDark),
              ),
            ),
            // Customer Name
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                entry.customerName,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: textDark,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            // Currency
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text(
                targetCurrency,
                style: pw.TextStyle(fontSize: 8.5, color: textDark),
              ),
            ),
            // Debit
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                convertedDebit > 0 ? convertedDebit.toStringAsFixed(2) : '-',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: convertedDebit > 0
                      ? PdfColor.fromHex('#C62828')
                      : textDark,
                  fontWeight: convertedDebit > 0
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ),
            // Credit
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                convertedCredit != 0 ? convertedCredit.toStringAsFixed(2) : '-',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: convertedCredit > 0
                      ? PdfColor.fromHex('#2E7D32')
                      : textDark,
                  fontWeight: convertedCredit != 0
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ),
            // Balance
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                convertedBalance.toStringAsFixed(2),
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: textDark,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Summary Rows
    final summaryBg = PdfColor.fromHex('#EEEEEE');

    // 1. Total Debit Row
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: summaryBg,
          border: pw.Border(
            top: pw.BorderSide(color: primaryColor, width: 1),
            bottom: pw.BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Text(
              'Total Debit',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          pw.Container(),
          pw.Container(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            alignment: pw.Alignment.center,
            child: pw.Text(
              targetCurrency,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              convertedTotalDebit.toStringAsFixed(2),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#C62828'),
              ),
            ),
          ),
          pw.Container(),
          pw.Container(),
        ],
      ),
    );

    // 2. Total Credit Row
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: summaryBg,
          border: pw.Border(
            bottom: pw.BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Text(
              'Total Credit',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          pw.Container(),
          pw.Container(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            alignment: pw.Alignment.center,
            child: pw.Text(
              targetCurrency,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              convertedTotalCredit.toStringAsFixed(2),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#2E7D32'),
              ),
            ),
          ),
          pw.Container(),
        ],
      ),
    );

    // 3. Closing Balance Row
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: summaryBg,
          border: pw.Border(
            bottom: pw.BorderSide(color: primaryColor, width: 1),
          ),
        ),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Text(
              'Closing Balance',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          pw.Container(),
          pw.Container(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            alignment: pw.Alignment.center,
            child: pw.Text(
              targetCurrency,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(),
          pw.Container(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              convertedTotalBalance.toStringAsFixed(2),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2), // Approved At
        1: const pw.FlexColumnWidth(1.5), // Invoice Ref
        2: const pw.FlexColumnWidth(2.5), // Customer Name
        3: const pw.FlexColumnWidth(0.9), // Currency
        4: const pw.FlexColumnWidth(1.1), // Debit
        5: const pw.FlexColumnWidth(1.1), // Credit
        6: const pw.FlexColumnWidth(1.1), // Balance
      },
      children: tableRows,
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute:$second';
  }
}

/// Excel Report Generator for Incentive Reports
class ExcelReportGenerator {
  static Future<List<int>> generateIncentiveReport({
    required List<SalesReportEntry> entries,
    required SalesReportResponse reportData,
    required String targetCurrency,
  }) async {
    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.showGridlines = true;

    // Apply Page Settings
    _applyPageSettings(sheet);

    // Create Report Header
    _createReportHeader(sheet, workbook, targetCurrency);

    // Create Table Header
    _createTableHeader(sheet, workbook);

    // Populate Data Rows
    final int lastDataRow = _populateDataRows(
      sheet,
      workbook,
      entries,
      targetCurrency,
    );

    // Create Summary Section
    final int summaryStartRow = lastDataRow + 2;
    _createSummarySection(
      sheet,
      workbook,
      summaryStartRow,
      reportData,
      targetCurrency,
    );

    // Apply Auto Filter
    sheet.autoFilters.filterRange = sheet.getRangeByIndex(5, 1, lastDataRow, 7);

    // Freeze Headers
    sheet.getRangeByIndex(6, 1).freezePanes();

    // Auto Fit Columns
    _autoFitWorksheet(sheet);

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  static void _applyPageSettings(xlsio.Worksheet sheet) {
    final xlsio.PageSetup pageSetup = sheet.pageSetup;
    pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
    pageSetup.paperSize = xlsio.ExcelPaperSize.paperA4;
    pageSetup.isFitToPage = true;
    pageSetup.fitToPagesWide = 1;
    pageSetup.fitToPagesTall = 0;
    pageSetup.isCenterHorizontally = true;
    pageSetup.isCenterVertically = false;
    pageSetup.leftMargin = 0.5;
    pageSetup.rightMargin = 0.5;
    pageSetup.topMargin = 0.5;
    pageSetup.bottomMargin = 0.5;
  }

  static void _createReportHeader(
    xlsio.Worksheet sheet,
    xlsio.Workbook workbook,
    String targetCurrency,
  ) {
    // Merge cells for the title: A1 to G2
    sheet.getRangeByIndex(1, 1, 2, 7).merge();

    final xlsio.Range titleCell = sheet.getRangeByIndex(1, 1);
    titleCell.setText('INCENTIVE REPORT');

    final xlsio.Style titleStyle = workbook.styles.add('titleStyle');
    titleStyle.backColor = '#1E3A8A';
    titleStyle.fontColor = '#FFFFFF';
    titleStyle.fontSize = 18;
    titleStyle.bold = true;
    titleStyle.hAlign = xlsio.HAlignType.center;
    titleStyle.vAlign = xlsio.VAlignType.center;

    sheet.getRangeByIndex(1, 1, 2, 7).cellStyle = titleStyle;
    sheet.getRangeByIndex(1, 1).rowHeight = 22;
    sheet.getRangeByIndex(2, 1).rowHeight = 22;

    // Metadata: Generated On and Currency
    final xlsio.Style metaLabelStyle = workbook.styles.add('metaLabelStyle');
    metaLabelStyle.fontSize = 10;
    metaLabelStyle.bold = true;
    metaLabelStyle.vAlign = xlsio.VAlignType.center;

    final xlsio.Style metaValueStyle = workbook.styles.add('metaValueStyle');
    metaValueStyle.fontSize = 10;
    metaValueStyle.vAlign = xlsio.VAlignType.center;

    // Row 3: Generated On
    sheet.getRangeByIndex(3, 1).setText('Generated On :');
    sheet.getRangeByIndex(3, 1).cellStyle = metaLabelStyle;

    sheet.getRangeByIndex(3, 2).setText(_formatDateTime(DateTime.now()));
    sheet.getRangeByIndex(3, 2).cellStyle = metaValueStyle;
    sheet.getRangeByIndex(3, 1).rowHeight = 20;

    // Row 4: Currency
    sheet.getRangeByIndex(4, 1).setText('Currency :');
    sheet.getRangeByIndex(4, 1).cellStyle = metaLabelStyle;

    sheet.getRangeByIndex(4, 2).setText(targetCurrency);
    sheet.getRangeByIndex(4, 2).cellStyle = metaValueStyle;
    sheet.getRangeByIndex(4, 1).rowHeight = 20;
  }

  static void _createTableHeader(
    xlsio.Worksheet sheet,
    xlsio.Workbook workbook,
  ) {
    final headers = [
      'Approved At',
      'Invoice Reference',
      'Customer Name',
      'Currency',
      'Debit',
      'Credit',
      'Balance',
    ];

    final xlsio.Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.backColor = '#1E3A8A';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    headerStyle.fontSize = 11;
    headerStyle.hAlign = xlsio.HAlignType.center;
    headerStyle.vAlign = xlsio.VAlignType.center;
    headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    headerStyle.borders.all.color = '#D3D3D3';

    for (int col = 1; col <= headers.length; col++) {
      final xlsio.Range cell = sheet.getRangeByIndex(5, col);
      cell.setText(headers[col - 1]);
      cell.cellStyle = headerStyle;
    }
    sheet.getRangeByIndex(5, 1).rowHeight = 25;
  }

  static int _populateDataRows(
    xlsio.Worksheet sheet,
    xlsio.Workbook workbook,
    List<SalesReportEntry> entries,
    String targetCurrency,
  ) {
    // Create shared styles
    final leftOdd = _createCellStyle(
      workbook,
      'leftOdd',
      null,
      xlsio.HAlignType.left,
    );
    final leftEven = _createCellStyle(
      workbook,
      'leftEven',
      '#F7F9FC',
      xlsio.HAlignType.left,
    );

    final centerOdd = _createCellStyle(
      workbook,
      'centerOdd',
      null,
      xlsio.HAlignType.center,
    );
    final centerEven = _createCellStyle(
      workbook,
      'centerEven',
      '#F7F9FC',
      xlsio.HAlignType.center,
    );

    final dateOdd = _createCellStyle(
      workbook,
      'dateOdd',
      null,
      xlsio.HAlignType.center,
      numberFormat: 'dd-mmm-yyyy',
    );
    final dateEven = _createCellStyle(
      workbook,
      'dateEven',
      '#F7F9FC',
      xlsio.HAlignType.center,
      numberFormat: 'dd-mmm-yyyy',
    );

    final rightOdd = _createCellStyle(
      workbook,
      'rightOdd',
      null,
      xlsio.HAlignType.right,
      numberFormat: '#,##0.00',
    );
    final rightEven = _createCellStyle(
      workbook,
      'rightEven',
      '#F7F9FC',
      xlsio.HAlignType.right,
      numberFormat: '#,##0.00',
    );

    int currentRow = 6;
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isEven = i % 2 == 1;

      final styleL = isEven ? leftEven : leftOdd;
      final styleC = isEven ? centerEven : centerOdd;
      final styleD = isEven ? dateEven : dateOdd;
      final styleR = isEven ? rightEven : rightOdd;

      final convertedDebit = CurrencyUtils.convertAmount(
        entry.debit,
        'AED',
        targetCurrency,
      );
      final convertedCredit = CurrencyUtils.convertAmount(
        entry.commissionAmount,
        'AED',
        targetCurrency,
      );
      final convertedBalance = CurrencyUtils.convertAmount(
        entry.balance,
        'AED',
        targetCurrency,
      );

      // 1. Approved At Date
      final c1 = sheet.getRangeByIndex(currentRow, 1);
      final parsedDate = DateTime.tryParse(entry.approvedAt);
      if (parsedDate != null) {
        c1.setDateTime(parsedDate);
        c1.cellStyle = styleD;
      } else if (entry.approvedAt.isNotEmpty) {
        c1.setText(entry.approvedAt);
        c1.cellStyle = styleC;
      } else {
        c1.setText('');
        c1.cellStyle = styleC;
      }

      // 2. Invoice Reference
      final c2 = sheet.getRangeByIndex(currentRow, 2);
      c2.setText(entry.invoiceReferenceNo);
      c2.cellStyle = styleL;

      // 3. Customer Name
      final c3 = sheet.getRangeByIndex(currentRow, 3);
      c3.setText(entry.customerName);
      c3.cellStyle = styleL;

      // 4. Currency
      final c4 = sheet.getRangeByIndex(currentRow, 4);
      c4.setText(targetCurrency);
      c4.cellStyle = styleC;

      // 5. Debit
      final c5 = sheet.getRangeByIndex(currentRow, 5);
      c5.setNumber(convertedDebit);
      c5.cellStyle = styleR;

      // 6. Credit
      final c6 = sheet.getRangeByIndex(currentRow, 6);
      c6.setNumber(convertedCredit);
      c6.cellStyle = styleR;

      // 7. Balance
      final c7 = sheet.getRangeByIndex(currentRow, 7);
      c7.setNumber(convertedBalance);
      c7.cellStyle = styleR;

      sheet.getRangeByIndex(currentRow, 1).rowHeight = 20;
      currentRow++;
    }
    return currentRow - 1;
  }

  static void _createSummarySection(
    xlsio.Worksheet sheet,
    xlsio.Workbook workbook,
    int summaryStartRow,
    SalesReportResponse reportData,
    String targetCurrency,
  ) {
    // 1. Create styles
    final xlsio.Style summaryLabelStyle = workbook.styles.add(
      'summaryLabelStyle',
    );
    summaryLabelStyle.backColor = '#EEEEEE';
    summaryLabelStyle.bold = true;
    summaryLabelStyle.fontSize = 10;
    summaryLabelStyle.hAlign = xlsio.HAlignType.left;
    summaryLabelStyle.vAlign = xlsio.VAlignType.center;
    summaryLabelStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryLabelStyle.borders.all.color = '#D3D3D3';
    summaryLabelStyle.borders.top.lineStyle = xlsio.LineStyle.medium;

    final xlsio.Style summaryValueStyle = workbook.styles.add(
      'summaryValueStyle',
    );
    summaryValueStyle.backColor = '#EEEEEE';
    summaryValueStyle.bold = true;
    summaryValueStyle.fontSize = 10;
    summaryValueStyle.hAlign = xlsio.HAlignType.right;
    summaryValueStyle.vAlign = xlsio.VAlignType.center;
    summaryValueStyle.numberFormat = '#,##0.00';
    summaryValueStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryValueStyle.borders.all.color = '#D3D3D3';
    summaryValueStyle.borders.top.lineStyle = xlsio.LineStyle.medium;

    final xlsio.Style summaryEmptyStyle = workbook.styles.add(
      'summaryEmptyStyle',
    );
    summaryEmptyStyle.backColor = '#EEEEEE';
    summaryEmptyStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryEmptyStyle.borders.all.color = '#D3D3D3';
    summaryEmptyStyle.borders.top.lineStyle = xlsio.LineStyle.medium;

    // Styles for rows 2 and 3 of summary (no thick top border)
    final xlsio.Style summaryLabelStyleSub = workbook.styles.add(
      'summaryLabelStyleSub',
    );
    summaryLabelStyleSub.backColor = '#EEEEEE';
    summaryLabelStyleSub.bold = true;
    summaryLabelStyleSub.fontSize = 10;
    summaryLabelStyleSub.hAlign = xlsio.HAlignType.left;
    summaryLabelStyleSub.vAlign = xlsio.VAlignType.center;
    summaryLabelStyleSub.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryLabelStyleSub.borders.all.color = '#D3D3D3';

    final xlsio.Style summaryValueStyleSub = workbook.styles.add(
      'summaryValueStyleSub',
    );
    summaryValueStyleSub.backColor = '#EEEEEE';
    summaryValueStyleSub.bold = true;
    summaryValueStyleSub.fontSize = 10;
    summaryValueStyleSub.hAlign = xlsio.HAlignType.right;
    summaryValueStyleSub.vAlign = xlsio.VAlignType.center;
    summaryValueStyleSub.numberFormat = '#,##0.00';
    summaryValueStyleSub.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryValueStyleSub.borders.all.color = '#D3D3D3';

    final xlsio.Style summaryEmptyStyleSub = workbook.styles.add(
      'summaryEmptyStyleSub',
    );
    summaryEmptyStyleSub.backColor = '#EEEEEE';
    summaryEmptyStyleSub.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryEmptyStyleSub.borders.all.color = '#D3D3D3';

    // Convert totals
    final convertedTotalDebit = CurrencyUtils.convertAmount(
      reportData.totalDebit,
      'AED',
      targetCurrency,
    );
    final convertedTotalCredit = CurrencyUtils.convertAmount(
      reportData.totalCommission,
      'AED',
      targetCurrency,
    );
    final convertedTotalBalance = CurrencyUtils.convertAmount(
      reportData.totalAmount,
      'AED',
      targetCurrency,
    );

    // Row 1: Total Debit
    sheet.getRangeByIndex(summaryStartRow, 1, summaryStartRow, 3).merge();
    sheet.getRangeByIndex(summaryStartRow, 1).setText('Total Debit');
    for (int c = 1; c <= 7; c++) {
      final cell = sheet.getRangeByIndex(summaryStartRow, c);
      if (c <= 3) {
        cell.cellStyle = summaryLabelStyle;
      } else if (c == 4) {
        cell.setText(targetCurrency);
        cell.cellStyle = summaryLabelStyle;
      } else if (c == 5) {
        cell.setNumber(convertedTotalDebit);
        cell.cellStyle = summaryValueStyle;
      } else {
        cell.cellStyle = summaryEmptyStyle;
      }
    }
    sheet.getRangeByIndex(summaryStartRow, 1).rowHeight = 22;

    // Row 2: Total Credit
    final int summaryRow2 = summaryStartRow + 1;
    sheet.getRangeByIndex(summaryRow2, 1, summaryRow2, 3).merge();
    sheet.getRangeByIndex(summaryRow2, 1).setText('Total Credit');
    for (int c = 1; c <= 7; c++) {
      final cell = sheet.getRangeByIndex(summaryRow2, c);
      if (c <= 3) {
        cell.cellStyle = summaryLabelStyleSub;
      } else if (c == 4) {
        cell.setText(targetCurrency);
        cell.cellStyle = summaryLabelStyleSub;
      } else if (c == 6) {
        cell.setNumber(convertedTotalCredit);
        cell.cellStyle = summaryValueStyleSub;
      } else {
        cell.cellStyle = summaryEmptyStyleSub;
      }
    }
    sheet.getRangeByIndex(summaryRow2, 1).rowHeight = 22;

    // Row 3: Closing Balance
    final int summaryRow3 = summaryRow2 + 1;
    sheet.getRangeByIndex(summaryRow3, 1, summaryRow3, 3).merge();
    sheet.getRangeByIndex(summaryRow3, 1).setText('Closing Balance');
    for (int c = 1; c <= 7; c++) {
      final cell = sheet.getRangeByIndex(summaryRow3, c);
      if (c <= 3) {
        cell.cellStyle = summaryLabelStyleSub;
      } else if (c == 4) {
        cell.setText(targetCurrency);
        cell.cellStyle = summaryLabelStyleSub;
      } else if (c == 7) {
        cell.setNumber(convertedTotalBalance);
        cell.cellStyle = summaryValueStyleSub;
      } else {
        cell.cellStyle = summaryEmptyStyleSub;
      }
    }
    sheet.getRangeByIndex(summaryRow3, 1).rowHeight = 22;
  }

  static void _autoFitWorksheet(xlsio.Worksheet sheet) {
    for (int col = 1; col <= 7; col++) {
      sheet.autoFitColumn(col);
      // Ensure a reasonable minimum width so headers aren't cramped
      if (sheet.getRangeByIndex(1, col).columnWidth < 13.0) {
        sheet.getRangeByIndex(1, col).columnWidth = 13.0;
      }
    }
  }

  static xlsio.Style _createCellStyle(
    xlsio.Workbook wb,
    String name,
    String? backColor,
    xlsio.HAlignType hAlign, {
    String? numberFormat,
  }) {
    final xlsio.Style style = wb.styles.add(name);
    style.fontSize = 10;
    style.vAlign = xlsio.VAlignType.center;
    style.hAlign = hAlign;
    style.borders.all.lineStyle = xlsio.LineStyle.thin;
    style.borders.all.color = '#E0E0E0';
    if (backColor != null) {
      style.backColor = backColor;
    }
    if (numberFormat != null) {
      style.numberFormat = numberFormat;
    }
    return style;
  }

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute:$second';
  }
}

/// Unified Export Handler for both PDF and Excel
class IncentiveReportExporter {
  static Future<void> exportReport({
    required BuildContext context,
    required List<SalesReportEntry> entries,
    required SalesReportResponse reportData,
    required String targetCurrency,
    required bool isPdf,
  }) async {
    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No data available to export.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    final fileType = isPdf ? 'PDF' : 'Excel';
    final fileExt = isPdf ? 'pdf' : 'xlsx';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating $fileType document...'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    try {
      final List<int> bytes = isPdf
          ? await PdfReportGenerator.generateIncentiveReport(
              entries: entries,
              reportData: reportData,
              targetCurrency: targetCurrency,
            )
          : await ExcelReportGenerator.generateIncentiveReport(
              entries: entries,
              reportData: reportData,
              targetCurrency: targetCurrency,
            );

      Directory? dir;
      if (Platform.isAndroid) {
        try {
          final publicDownloadDir = Directory('/storage/emulated/0/Download');
          if (await publicDownloadDir.exists()) {
            final testFile = File('${publicDownloadDir.path}/.test_write');
            await testFile.writeAsString('test');
            await testFile.delete();
            dir = publicDownloadDir;
          }
        } catch (_) {}
      }

      if (dir == null) {
        try {
          dir = await getDownloadsDirectory();
        } catch (_) {}
      }

      if (dir == null && Platform.isAndroid) {
        try {
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          if (dirs != null && dirs.isNotEmpty) {
            dir = dirs.first;
          }
        } catch (_) {}
      }

      dir ??= await getTemporaryDirectory();

      final file = File(
        '${dir.path}/Incentive_Report_${DateTime.now().millisecondsSinceEpoch}.$fileExt',
      );
      await file.writeAsBytes(bytes);

      await OpenFilex.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$fileType saved to Downloads/Files: ${file.path.split(Platform.pathSeparator).last}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating $fileType: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
