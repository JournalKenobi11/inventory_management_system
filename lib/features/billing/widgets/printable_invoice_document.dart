import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../export/export.dart';

/// A pixel-perfect Flutter widget representation of the official PDF Invoice document.
/// Used to capture and share crystal-clear PNG images of the formal bill containing
/// the shop branding, metadata, itemized table, totals, and UPI payment QR code.
class PrintableInvoiceDocument extends StatelessWidget {
  final InvoicePdfData data;

  const PrintableInvoiceDocument({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header Section
          _buildHeader(),
          const SizedBox(height: 14),
          const Divider(thickness: 1.5, color: Color(0xFF37474F), height: 1.5),
          const SizedBox(height: 12),

          // 2. Meta Details (Customer & Invoice)
          _buildMetaDetails(),
          const SizedBox(height: 16),

          // 3. Items Table (Parts + Labour)
          _buildItemsTable(),
          const SizedBox(height: 14),

          // 4. Totals & UPI QR Code Section
          _buildTotalsSection(),
          const SizedBox(height: 14),

          // 5. Service Report (if present)
          if (data.service.serviceReport != null &&
              data.service.serviceReport!.trim().isNotEmpty) ...[
            _buildServiceReportSection(),
            const SizedBox(height: 12),
          ],

          // 6. Terms and Conditions
          _buildTermsAndConditionsSection(),
          const SizedBox(height: 18),

          // 7. Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.garageName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                  height: 1.2,
                ),
              ),
              if (data.garageServices != null &&
                  data.garageServices!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  data.garageServices!.trim(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF455A64),
                  ),
                ),
              ],
              if (data.garageAddress != null &&
                  data.garageAddress!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  data.garageAddress!.trim(),
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              if (data.garagePhone != null &&
                  data.garagePhone!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Phone: ${data.garagePhone!.trim()}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              if (data.isGstRegistered && data.gstNumber != null) ...[
                const SizedBox(height: 2),
                Text(
                  'GSTIN: ${data.gstNumber!}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF37474F),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            data.isGstRegistered ? 'TAX INVOICE' : 'INVOICE',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaDetails() {
    final invoiceDate = data.invoice.createdDate.length >= 10
        ? data.invoice.createdDate.substring(0, 10)
        : data.invoice.createdDate;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Column: Customer details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CUSTOMER DETAILS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF455A64),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.customer.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Mobile: ${data.customer.mobile}',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
              if (data.customer.vehicleName != null &&
                  data.customer.vehicleName!.trim().isNotEmpty)
                Text(
                  'Vehicle: ${data.customer.vehicleName!}',
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              if (data.service.problemDesc != null &&
                  data.service.problemDesc!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Issue: ${data.service.problemDesc!}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Right Column: Invoice metadata
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'INVOICE DETAILS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF455A64),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Invoice No: #${data.invoice.invoiceNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Date: $invoiceDate',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
              Text(
                'Service ID: ${data.service.id.length > 8 ? data.service.id.substring(0, 8) : data.service.id}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    var slNo = 1;

    final rows = <TableRow>[
      // Table Header Row
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFFECEFF1)),
        children: [
          _tableCell('#', isHeader: true),
          _tableCell('Description', isHeader: true),
          _tableCell('Qty', isHeader: true, alignRight: true),
          _tableCell('Rate (₹)', isHeader: true, alignRight: true),
          _tableCell('Total (₹)', isHeader: true, alignRight: true),
        ],
      ),
    ];

    // Parts rows
    for (final item in data.parts) {
      final desc = item.partNumber.isNotEmpty
          ? '${item.partName} (${item.partNumber})'
          : item.partName;
      rows.add(
        TableRow(
          children: [
            _tableCell('${slNo++}'),
            _tableCell(desc),
            _tableCell('${item.quantity}', alignRight: true),
            _tableCell(item.priceEach.toStringAsFixed(2), alignRight: true),
            _tableCell(item.lineTotal.toStringAsFixed(2), alignRight: true),
          ],
        ),
      );
    }

    // Labour rows
    if (data.service.labourEntries.isNotEmpty) {
      for (final labour in data.service.labourEntries) {
        rows.add(
          TableRow(
            children: [
              _tableCell('${slNo++}'),
              _tableCell(labour.description, isBold: true),
              _tableCell('1', alignRight: true),
              _tableCell(labour.charge.toStringAsFixed(2), alignRight: true),
              _tableCell(labour.charge.toStringAsFixed(2), alignRight: true),
            ],
          ),
        );
      }
    } else if (data.labourCharge > 0) {
      rows.add(
        TableRow(
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

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
      columnWidths: const {
        0: FixedColumnWidth(30),
        1: FlexColumnWidth(4),
        2: FixedColumnWidth(48),
        3: FixedColumnWidth(80),
        4: FixedColumnWidth(90),
      },
      children: rows,
    );
  }

  Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    bool alignRight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: isHeader ? 10 : 9.5,
          fontWeight: (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? const Color(0xFF37474F) : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Official Dynamic UPI QR Code Box
        if (data.upiUri != null && data.upiUri!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: data.upiUri!,
                  version: QrVersions.auto,
                  size: 80.0,
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F172A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scan to Pay via UPI',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'GPay • PhonePe • Paytm • BHIM',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(),

        // Right Column: Cost Breakdown Totals
        SizedBox(
          width: 240,
          child: Column(
            children: [
              _amountRow('Parts Subtotal', data.partsTotal),
              if (data.labourCharge > 0)
                _amountRow('Labour Charge', data.labourCharge),
              Divider(color: Colors.grey.shade300, height: 6),
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
                Divider(color: Colors.grey.shade300, height: 6),
              ],
              Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF37474F), width: 1),
                    bottom: BorderSide(color: Color(0xFF37474F), width: 2),
                  ),
                ),
                child: _amountRow(
                  'Grand Total',
                  data.grandTotal,
                  isBold: true,
                  fontSize: 12.5,
                ),
              ),
              if (data.invoice.advanceAmount > 0) ...[
                const SizedBox(height: 2),
                _amountRow(
                  'Advance Paid',
                  -data.invoice.advanceAmount,
                ),
                Divider(color: Colors.grey.shade300, height: 6),
                _amountRow(
                  'Balance Due / Payable',
                  data.invoice.balanceDue,
                  isBold: true,
                  fontSize: 12,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 10,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? const Color(0xFF1E293B) : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFF1E293B) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SERVICE REPORT & TECHNICIAN NOTES',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF455A64),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 0.8),
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFFFAFAFA),
          ),
          child: Text(
            data.service.serviceReport!.trim(),
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TERMS & CONDITIONS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF455A64),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        _termItem('1. Payment is due upon receipt of invoice.'),
        _termItem('2. Warranty on new parts is subject to manufacturer terms and conditions.'),
        _termItem('3. Electrical and electronic parts carry no replacement warranty once fitted.'),
        _termItem('4. Vehicles not collected within 7 days of service completion may incur parking fees.'),
      ],
    );
  }

  Widget _termItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7.5,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(color: Colors.grey.shade300, height: 1),
        const SizedBox(height: 8),
        Text(
          'Thank you for choosing ${data.garageName}!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'This is a computer-generated invoice. No physical signature is required.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 7.5,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
