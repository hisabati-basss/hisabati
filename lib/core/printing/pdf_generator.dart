// lib/core/printing/pdf_generator.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/app_constants.dart';

/// Lightweight model classes for PDF generation (SQLite-compatible).
/// These replace the old Isar collection types.
class PdfCompanyInfo {
  final String name;
  final String? taxId;
  final String? address;
  PdfCompanyInfo({required this.name, this.taxId, this.address});

  factory PdfCompanyInfo.fromMap(Map<String, dynamic> map) => PdfCompanyInfo(
    name: map['name'] ?? '',
    taxId: map['tax_id'],
    address: map['address'],
  );
}

class PdfInvoiceInfo {
  final String invoiceNumber;
  final DateTime date;
  final String? partnerName;
  final double netAmount;
  final double totalTax;
  final double totalAmount;
  PdfInvoiceInfo({required this.invoiceNumber, required this.date, this.partnerName, required this.netAmount, required this.totalTax, required this.totalAmount});

  factory PdfInvoiceInfo.fromMap(Map<String, dynamic> map) => PdfInvoiceInfo(
    invoiceNumber: map['invoice_number'] ?? map['id'] ?? '',
    date: DateTime.tryParse(map['issue_date'] ?? '') ?? DateTime.now(),
    partnerName: map['client_name'] ?? map['partner_name'],
    netAmount: (map['subtotal'] as num?)?.toDouble() ?? 0,
    totalTax: (map['tax_amount'] as num?)?.toDouble() ?? 0,
    totalAmount: (map['total'] as num?)?.toDouble() ?? 0,
  );
}

class PdfInvoiceLineInfo {
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double totalLine;
  PdfInvoiceLineInfo({required this.itemName, required this.quantity, required this.unitPrice, required this.totalLine});

  factory PdfInvoiceLineInfo.fromMap(Map<String, dynamic> map) => PdfInvoiceLineInfo(
    itemName: map['name'] ?? '---',
    quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
    unitPrice: (map['price_at_sale'] as num?)?.toDouble() ?? 0,
    totalLine: ((map['quantity'] as num?)?.toDouble() ?? 0) * ((map['price_at_sale'] as num?)?.toDouble() ?? 0),
  );
}

class PdfGenerator {
  static final PdfGenerator _instance = PdfGenerator._internal();
  factory PdfGenerator() => _instance;
  PdfGenerator._internal();

  /// Generates a professional A4 Sales Invoice
  Future<void> generateInvoicePdf(PdfCompanyInfo company, PdfInvoiceInfo invoice, List<PdfInvoiceLineInfo> lines) async {
    final pdf = pw.Document();
    
    // Load Arabic Font (Essential for RTL support)
    final font = await PdfGoogleFonts.amiriRegular();
    final boldFont = await PdfGoogleFonts.amiriBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(company),
          pw.SizedBox(height: 20),
          _buildInvoiceDetails(invoice),
          pw.SizedBox(height: 20),
          _buildItemsTable(lines),
          pw.SizedBox(height: 20),
          _buildSummary(invoice),
          _buildFooter(company),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildHeader(PdfCompanyInfo company) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(company.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            if (company.taxId != null) pw.Text("الرقم الضريبي: ${company.taxId}"),
            if (company.address != null) pw.Text(company.address!),
          ],
        ),
        // If logo existed, it would go here
        pw.Container(width: 60, height: 60, color: PdfColors.grey300), 
      ],
    );
  }

  pw.Widget _buildInvoiceDetails(PdfInvoiceInfo invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("فاتورة مبيعات ضريبية", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
        pw.Text("رقم الفاتورة: ${invoice.invoiceNumber}"),
        pw.Text("التاريخ: ${invoice.date.toIso8601String().split('T')[0]}"),
        if (invoice.partnerName != null) pw.Text("العميل: ${invoice.partnerName}"),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<PdfInvoiceLineInfo> lines) {
    return pw.TableHelper.fromTextArray(
      headers: ['الصنف', 'الكمية', 'السعر', 'الإجمالي'],
      data: lines.map((l) => [l.itemName, l.quantity, l.unitPrice, l.totalLine]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
      cellAlignment: pw.Alignment.centerRight,
    );
  }

  pw.Widget _buildSummary(PdfInvoiceInfo invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text("المجموع الفرعي: ${invoice.netAmount}"),
          pw.Text("الضريبة (15%): ${invoice.totalTax}"),
          pw.Divider(),
          pw.Text("الإجمالي النهائي: ${invoice.totalAmount}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(PdfCompanyInfo company) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 40),
      alignment: pw.Alignment.center,
      child: pw.Text("شكراً لتعاملكم معنا", style: pw.TextStyle(color: PdfColors.grey600)),
    );
  }
}
