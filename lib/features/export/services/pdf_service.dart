import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../reports/models/report_models.dart';
import '../models/export_models.dart';

class PdfService {
  Future<Uint8List> generateInvoicePdf(InvoicePdfData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(data),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1.5, color: PdfColors.blueGrey800),
              pw.SizedBox(height: 12),
              _buildMetaDetails(data),
              pw.SizedBox(height: 16),
              _buildItemsTable(data),
              pw.SizedBox(height: 16),
              _buildTotalsSection(data),
              pw.Spacer(),
              _buildFooter(data),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<File> saveInvoicePdfToFile(
    InvoicePdfData data, {
    String? customFileName,
  }) async {
    final bytes = await generateInvoicePdf(data);
    final tempDir = await getTemporaryDirectory();
    final fileName =
        customFileName ?? 'Invoice_${data.invoice.invoiceNumber}.pdf';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> downloadInvoicePdf(
    InvoicePdfData data, {
    String? customFileName,
  }) async {
    final bytes = await generateInvoicePdf(data);
    Directory? saveDir;
    try {
      saveDir = await getDownloadsDirectory();
    } catch (_) {}

    if (saveDir == null && Platform.isAndroid) {
      final androidDownload = Directory('/storage/emulated/0/Download');
      if (await androidDownload.exists()) {
        saveDir = androidDownload;
      }
    }

    saveDir ??= await getApplicationDocumentsDirectory();

    final fileName =
        customFileName ?? 'Invoice_${data.invoice.invoiceNumber}.pdf';
    final file = File(p.join(saveDir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Uint8List> generateReportPdf(
    ComprehensiveReport report, {
    String garageName = 'Auto Care Garage & Service Center',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        garageName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'BUSINESS PERFORMANCE REPORT',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Period: ${report.range.label}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Generated: ${report.generatedAt.toIso8601String().substring(0, 10)}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 12),
              pw.Text(
                'Financial Summary',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _tableCell('Metric', isHeader: true),
                      _tableCell('Amount', isHeader: true, alignRight: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell(
                        'Total Sales (${report.sales.invoiceCount} invoices)',
                      ),
                      _tableCell(
                        'Rs. ${report.sales.totalSales.toStringAsFixed(2)}',
                        alignRight: true,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Business Expenses'),
                      _tableCell(
                        'Rs. ${report.expenses.totalBusinessExpenses.toStringAsFixed(2)}',
                        alignRight: true,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Staff Salary Expenses (Paid)'),
                      _tableCell(
                        'Rs. ${report.expenses.totalSalaryExpenses.toStringAsFixed(2)}',
                        alignRight: true,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Total Expenses (Business + Salaries)'),
                      _tableCell(
                        'Rs. ${report.expenses.totalExpenses.toStringAsFixed(2)}',
                        alignRight: true,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _tableCell(
                        'Net Profit (Margin: ${report.profit.profitMarginPercentage.toStringAsFixed(1)}%)',
                        isBold: true,
                      ),
                      _tableCell(
                        'Rs. ${report.profit.netProfit.toStringAsFixed(2)}',
                        isBold: true,
                        alignRight: true,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Operations & Inventory',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    children: [
                      _tableCell('Services / Jobs Completed'),
                      _tableCell(
                        '${report.servicesCompleted}',
                        alignRight: true,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Inventory Value'),
                      _tableCell(
                        'Rs. ${report.inventory.totalInventoryValue.toStringAsFixed(2)}',
                        alignRight: true,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Low Stock Items Count'),
                      _tableCell(
                        '${report.inventory.lowStockCount}',
                        alignRight: true,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<File> savePdfToFile(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    return file.writeAsBytes(bytes);
  }

  pw.Widget _buildHeader(InvoicePdfData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              data.garageName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            if (data.garageAddress != null)
              pw.Text(
                data.garageAddress!,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            if (data.garagePhone != null)
              pw.Text(
                'Phone: ${data.garagePhone!}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            if (data.isGstRegistered && data.gstNumber != null)
              pw.Text(
                'GSTIN: ${data.gstNumber!}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey800,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            data.isGstRegistered ? 'TAX INVOICE' : 'INVOICE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMetaDetails(InvoicePdfData data) {
    final invoiceDate = data.invoice.createdDate.length >= 10
        ? data.invoice.createdDate.substring(0, 10)
        : data.invoice.createdDate;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CUSTOMER DETAILS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                data.customer.name,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Mobile: ${data.customer.mobile}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (data.customer.vehicleName != null)
                pw.Text(
                  'Vehicle: ${data.customer.vehicleName!}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (data.service.problemDesc != null &&
                  data.service.problemDesc!.isNotEmpty)
                pw.Text(
                  'Issue: ${data.service.problemDesc!}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE DETAILS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Invoice No: #${data.invoice.invoiceNumber}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Date: $invoiceDate',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Service ID: ${data.service.id.length > 8 ? data.service.id.substring(0, 8) : data.service.id}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(InvoicePdfData data) {
    var slNo = 1;
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
        children: [
          _tableCell('#', isHeader: true),
          _tableCell('Description', isHeader: true),
          _tableCell('Qty', isHeader: true, alignRight: true),
          _tableCell('Rate (Rs.)', isHeader: true, alignRight: true),
          _tableCell('Total (Rs.)', isHeader: true, alignRight: true),
        ],
      ),
    ];

    for (final item in data.parts) {
      rows.add(
        pw.TableRow(
          children: [
            _tableCell('${slNo++}'),
            _tableCell('${item.partName} (${item.partNumber})'),
            _tableCell('${item.quantity}', alignRight: true),
            _tableCell(item.priceEach.toStringAsFixed(2), alignRight: true),
            _tableCell(item.lineTotal.toStringAsFixed(2), alignRight: true),
          ],
        ),
      );
    }

    if (data.labourCharge > 0) {
      rows.add(
        pw.TableRow(
          children: [
            _tableCell('${slNo++}'),
            _tableCell('Labour / Service Charges', isBold: true),
            _tableCell('1', alignRight: true),
            _tableCell(data.labourCharge.toStringAsFixed(2), alignRight: true),
            _tableCell(data.labourCharge.toStringAsFixed(2), alignRight: true),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FixedColumnWidth(45),
        3: const pw.FixedColumnWidth(75),
        4: const pw.FixedColumnWidth(85),
      },
      children: rows,
    );
  }

  pw.Widget _buildTotalsSection(InvoicePdfData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 220,
          child: pw.Column(
            children: [
              _amountRow('Parts Subtotal', data.partsTotal),
              if (data.labourCharge > 0)
                _amountRow('Labour Charge', data.labourCharge),
              pw.Divider(color: PdfColors.grey300),
              _amountRow('Subtotal', data.subtotal, isBold: true),
              if (data.isGstRegistered) ...[
                _amountRow(
                  'CGST (${(data.gstRatePercentage / 2).toStringAsFixed(1)}%)',
                  data.cgstAmount,
                ),
                _amountRow(
                  'SGST (${(data.gstRatePercentage / 2).toStringAsFixed(1)}%)',
                  data.sgstAmount,
                ),
                pw.Divider(color: PdfColors.grey300),
              ],
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.blueGrey800, width: 1),
                    bottom: pw.BorderSide(
                      color: PdfColors.blueGrey800,
                      width: 2,
                    ),
                  ),
                ),
                child: _amountRow(
                  'Grand Total',
                  data.grandTotal,
                  isBold: true,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _amountRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(InvoicePdfData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.Text(
              'Authorized Signatory',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8.5,
          fontWeight: (isHeader || isBold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blueGrey900 : PdfColors.black,
        ),
      ),
    );
  }
}
