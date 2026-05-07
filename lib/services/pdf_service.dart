import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'qr_service.dart';
import '../utils/tafqeet.dart';

class PdfService {
  /// Generates and previews a premium PDF invoice.
  static Future<void> generateInvoice({
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> company,
    bool isThermal = false,
    String? customTitle,
  }) async {
    final pdf = pw.Document();

    final String country = company['country'] ?? 'مصر';
    final String companyName = company['name'] ?? 'منشأة افتراضية';
    final String companyLogoPath = company['logo_path'] ?? '';

    // 1. Load Company Custom Logo
    pw.ImageProvider? companyLogo;
    if (!kIsWeb && companyLogoPath.isNotEmpty) {
      try {
        final logoFile = File(companyLogoPath);
        if (await logoFile.exists()) {
          companyLogo = pw.MemoryImage(await logoFile.readAsBytes());
        }
      } catch (e) {
        debugPrint("Error loading company logo: $e");
      }
    }

    // 2. Load Application Logo
    pw.ImageProvider? appLogo;
    try {
      final ByteData data = await rootBundle.load('assets/image/logo icon.PNG');
      appLogo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}


    
    // Fetch Client Balance (To be linked with Isar Account logic later)
    final String clientId = invoice['client_id'] ?? 'CUST_DEMO';
    final double clientBalance = 0.0;
    
    // Determine Invoice Type
    final bool isCredit = invoice['payment_type'] == 'credit';
    final String titleText = customTitle ?? (isCredit 
        ? "${tr('pdf.tax_invoice')} - ${tr('pdf.credit')}" 
        : "${tr('pdf.tax_invoice')} (${tr('pdf.cash')})");

    // 2. Generate QR Data
    final String qrData = QrService.generateQrData(
      companyName: companyName,
      vatNumber: company['vat_number'] ?? '300000000000003',
      timestamp: DateTime.parse(invoice['issue_date']),
      totalWithVat: invoice['total'],
      vatAmount: invoice['tax_amount'],
      country: country,
    );

    // 3. Load Arabic Fonts safely
    pw.Font fontMedium;
    pw.Font fontBold;
    try {
      fontMedium = await PdfGoogleFonts.tajawalMedium();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (e) {
      fontMedium = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    // 4. Build PDF Layout
    final pageFormat = isThermal ? PdfPageFormat.roll80 : PdfPageFormat.a4;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                children: [
                  // Header Row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (appLogo != null)
                        pw.Container(width: 120, height: 80, child: pw.Image(appLogo, fit: pw.BoxFit.contain)),
                      pw.Row(
                         children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
                                pw.Text(company['address'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                                pw.Text("${tr('pdf.vat_number')}: ${company['vat_number'] ?? ''}", style: const pw.TextStyle(fontSize: 10)),
                              ],
                            ),
                            pw.SizedBox(width: 8),
                            if (companyLogo != null)
                               pw.Container(width: 50, height: 50, child: pw.Image(companyLogo, fit: pw.BoxFit.contain))
                         ]
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 32),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(titleText, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                            pw.Text("${tr('pdf.invoice_number')}: ${invoice['id']}", style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(tr('pdf.issue_date'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text(invoice['issue_date'].toString().split('T')[0], style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey200),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _buildHeaderCell(tr('pdf.item_desc')),
                          _buildHeaderCell(tr('pdf.quantity')),
                          _buildHeaderCell(tr('pdf.price')),
                          _buildHeaderCell(tr('pdf.total')),
                        ],
                      ),
                      ...items.map((item) => pw.TableRow(
                        children: [
                          _buildCell(item['name'] ?? 'صنف غير معروف'),
                          _buildCell("${item['quantity']}"),
                          _buildCell("${item['price_at_sale']}"),
                          _buildCell("${(item['quantity'] * item['price_at_sale']).toStringAsFixed(2)}"),
                        ],
                      )),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 100, height: 100,
                            child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: qrData, drawText: false),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(tr('pdf.scan_to_verify'), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Container(
                        width: 200,
                        child: pw.Column(
                          children: [
                            _buildSummaryRow(tr('pdf.subtotal'), "${invoice['subtotal']} ${company['currency']}"),
                            _buildSummaryRow(tr('pdf.vat_amount'), "${invoice['tax_amount']} ${company['currency']}"),
                            pw.Divider(color: PdfColors.orange200),
                            _buildSummaryRow(tr('pdf.total_due'), "${invoice['total']} ${company['currency']}", isTotal: true),
                            pw.SizedBox(height: 8),
                            pw.Text(Tafqeet.convert(invoice['total'], currency: company['currency'] ?? 'ريال'), 
                                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'invoice_${invoice['id']}.pdf');
    } else {
      if (Platform.isWindows || Platform.isMacOS || isThermal) {
         // Direct open print dialog for thermal or generic desktop
         await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes, name: 'invoice_${invoice['id']}');
      } else {
         await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
      }
    }
  }

  /// Generates and previews a Purchase Invoice PDF
  static Future<void> generatePurchaseInvoicePdf({
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    pw.Font fontMedium;
    pw.Font fontBold;
    try {
      fontMedium = await PdfGoogleFonts.tajawalMedium();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      fontMedium = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(company['name'] ?? '', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
                      pw.Text("فاتورة مشتريات\nPurchase Invoice", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text("رقم الفاتورة: ${invoice['id']}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("المورد: ${invoice['supplier_name'] ?? ''}", style: const pw.TextStyle(fontSize: 10)),
                        ]),
                        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                          pw.Text("التاريخ: ${invoice['issue_date']?.toString().split('T')[0] ?? ''}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("الحالة: ${invoice['status'] ?? 'draft'}", style: const pw.TextStyle(fontSize: 10)),
                        ]),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey200),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _buildHeaderCell(tr('pdf.item_desc')),
                          _buildHeaderCell(tr('pdf.quantity')),
                          _buildHeaderCell(tr('pdf.price')),
                          _buildHeaderCell(tr('pdf.total')),
                        ],
                      ),
                      ...items.map((item) => pw.TableRow(
                        children: [
                          _buildCell(item['name'] ?? ''),
                          _buildCell("${item['quantity']}"),
                          _buildCell("${item['price']}"),
                          _buildCell("${((item['quantity'] ?? 0) * (item['price'] ?? 0)).toStringAsFixed(2)}"),
                        ],
                      )),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Container(
                    width: 200,
                    child: pw.Column(children: [
                      _buildSummaryRow(tr('pdf.subtotal'), "${invoice['subtotal']} ${company['currency']}"),
                      _buildSummaryRow(tr('pdf.vat_amount'), "${invoice['tax_amount']} ${company['currency']}"),
                      pw.Divider(color: PdfColors.blue200),
                      _buildSummaryRow(tr('pdf.total_due'), "${invoice['total']} ${company['currency']}", isTotal: true),
                    ]),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'purchase_invoice_${invoice['id']}.pdf');
    } else {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    }
  }

  /// Generates and previews a Quotation PDF (عرض سعر)
  static Future<void> generateQuotationPdf({
    required Map<String, dynamic> quotation,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    pw.Font fontMedium;
    pw.Font fontBold;
    try {
      fontMedium = await PdfGoogleFonts.tajawalMedium();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      fontMedium = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text(company['name'] ?? '', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
                        pw.Text(company['address'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("${tr('pdf.vat_number')}: ${company['vat_number'] ?? ''}", style: const pw.TextStyle(fontSize: 10)),
                      ]),
                      pw.Text("عرض سعر\nQuotation", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    ],
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("العميل: ${quotation['client_name'] ?? ''}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("رقم العرض: ${quotation['id']}", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("تاريخ الإصدار: ${quotation['issue_date']?.toString().split('T')[0] ?? ''}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("صالح حتى: ${quotation['expiry_date']?.toString().split('T')[0] ?? ''}", style: pw.TextStyle(fontSize: 10, color: PdfColors.red)),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey200),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1),
                      4: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                        children: [
                          _buildHeaderCell("الصنف"),
                          _buildHeaderCell("الكمية"),
                          _buildHeaderCell("السعر"),
                          _buildHeaderCell("الضريبة"),
                          _buildHeaderCell("الإجمالي"),
                        ],
                      ),
                      ...items.map((item) => pw.TableRow(
                        children: [
                          _buildCell(item['name'] ?? ''),
                          _buildCell("${item['quantity']}"),
                          _buildCell("${item['price']}"),
                          _buildCell("${item['tax_rate'] ?? 0}%"),
                          _buildCell("${item['total'] ?? ((item['quantity'] ?? 0) * (item['price'] ?? 0)).toStringAsFixed(2)}"),
                        ],
                      )),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      width: 200,
                      child: pw.Column(children: [
                        _buildSummaryRow("المجموع", "${quotation['subtotal']} ${company['currency']}"),
                        _buildSummaryRow("الضريبة", "${quotation['tax_amount']} ${company['currency']}"),
                        pw.Divider(color: PdfColors.teal),
                        _buildSummaryRow("الإجمالي", "${quotation['total']} ${company['currency']}", isTotal: true),
                      ]),
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  if (quotation['notes'] != null && quotation['notes'].toString().isNotEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                      child: pw.Text("ملاحظات: ${quotation['notes']}", style: const pw.TextStyle(fontSize: 10)),
                    ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'quotation_${quotation['id']}.pdf');
    } else {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    }
  }

  /// Generates a Contracting Progress Invoice (مستخلص مقاولات)
  static Future<void> generateContractingInvoicePdf({
    required Map<String, dynamic> project,
    required Map<String, dynamic> invoice,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    pw.Font fontMedium;
    pw.Font fontBold;
    try {
      fontMedium = await PdfGoogleFonts.tajawalMedium();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      fontMedium = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final double totalValue = (project['total_value'] as num?)?.toDouble() ?? 0;
    final double completionPct = (invoice['total_completed_pct'] as num?)?.toDouble() ?? 0;
    final double materialOnSite = (invoice['material_on_site'] as num?)?.toDouble() ?? 0;
    final double advanceDeduction = (invoice['advance_deduction'] as num?)?.toDouble() ?? 0;
    final double retentionDeduction = (invoice['retention_deduction'] as num?)?.toDouble() ?? 0;
    final double netAmount = (invoice['net_amount'] as num?)?.toDouble() ?? 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text("مستخلص أعمال\nProgress Payment Certificate", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800))),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 12),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("المقاول: ${company['name']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("المستخلص رقم: ${invoice['invoice_number']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
              pw.Text("المشروع: ${project['name']}"),
              pw.Text("الفترة: ${invoice['period_start']} إلى ${invoice['period_end']}"),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.orange50), children: [
                    _buildHeaderCell("البند"),
                    _buildHeaderCell("القيمة"),
                  ]),
                  _summaryTableRow("قيمة العقد الإجمالية", "${_formatCurrency(totalValue)} ${company['currency']}"),
                  _summaryTableRow("نسبة الإنجاز التراكمية", "${completionPct.toStringAsFixed(1)}%"),
                  _summaryTableRow("قيمة الأعمال المنجزة", "${_formatCurrency(totalValue * completionPct / 100)} ${company['currency']}"),
                  _summaryTableRow("مواد بالموقع", "${_formatCurrency(materialOnSite)} ${company['currency']}"),
                  _summaryTableRow("(-) خصم دفعة مقدمة", "${_formatCurrency(advanceDeduction)} ${company['currency']}"),
                  _summaryTableRow("(-) محجوز ضمان", "${_formatCurrency(retentionDeduction)} ${company['currency']}"),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                color: PdfColors.green50,
                child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("صافي المستحق", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                  pw.Text("${_formatCurrency(netAmount)} ${company['currency']}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                ]),
              ),
              pw.SizedBox(height: 8),
              pw.Text("كتابةً: ${Tafqeet.convert(netAmount, currency: company['currency'] ?? 'ريال')}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 40),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
                pw.Column(children: [pw.Text("توقيع المقاول"), pw.SizedBox(height: 30), pw.Text("........................")]),
                pw.Column(children: [pw.Text("توقيع الاستشاري"), pw.SizedBox(height: 30), pw.Text("........................")]),
                pw.Column(children: [pw.Text("اعتماد المالك"), pw.SizedBox(height: 30), pw.Text("........................")]),
              ]),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'contracting_invoice_${invoice['invoice_number']}');
  }

  static pw.TableRow _summaryTableRow(String label, String value) {
    return pw.TableRow(children: [
      _buildCell(label),
      _buildCell(value, isBold: true),
    ]);
  }

  static Future<void> generateZakatReport({
    required Map<String, dynamic> data,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    final fontMedium = await PdfGoogleFonts.tajawalMedium();
    final fontBold = await PdfGoogleFonts.tajawalBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("تقرير تقدير الزكاة الشرعية", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    pw.Text(company['name'] ?? '', style: pw.TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text("تفاصيل الوعاء الزكوي:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(color: PdfColors.green),
              pw.SizedBox(height: 10),
              _buildSummaryRow("إجمالي الأصول الزكوية (Liquid Assets)", "${data['assets']} ${company['currency']}"),
              _buildSummaryRow("إجمالي الالتزامات المتداولة (Liabilities)", "${data['liabilities']} ${company['currency']}"),
              pw.Divider(),
              _buildSummaryRow("صافي الوعاء الزكوي (Zakat Pool)", "${data['pool']} ${company['currency']}", isTotal: true),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(color: PdfColors.green50),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("الزكاة المستحقة (2.5%)", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    pw.Text("${data['due']} ${company['currency']}", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text("ملاحظات:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("تم حساب الزكاة بناءً على الأرصدة الحالية في النظام المحاسبي وقت استخراج التقرير."),
              pw.Footer(
                margin: const pw.EdgeInsets.only(top: 20),
                trailing: pw.Text("التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}"),
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'zakat_report');
  }

  static Future<void> generateFinancialReport({
    required String type,
    required Map<String, double> data,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    pw.Font fontMedium;
    pw.Font fontBold;
    try {
      fontMedium = await PdfGoogleFonts.tajawalMedium();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      fontMedium = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("${company['name'] ?? ''} - $type", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                pw.Divider(),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                      children: [
                        _buildHeaderCell(tr('pdf.financial_item')),
                        _buildHeaderCell(tr('pdf.total_value')),
                      ],
                    ),
                    ...data.entries.map((e) => pw.TableRow(
                      children: [
                        _buildCell(_getFriendlyLabel(e.key)),
                        _buildCell("${_formatCurrency(e.value)} ${company['currency'] ?? 'ر.س'}"),
                      ],
                    )).toList(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'report_$type.pdf');
    } else {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    }
  }

  static Future<void> generateAccountStatementPdf({
    required String accountName,
    required List<Map<String, dynamic>> entries,
    required Map<String, dynamic> company,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    pw.Font fontMedium;
    pw.Font fontBold;
    try {
      fontMedium = await PdfGoogleFonts.tajawalMedium();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      fontMedium = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              children: [
                pw.Text("${tr('pdf.account_statement')}: $accountName", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                      children: [
                        _buildHeaderCell(tr('pdf.date')),
                        _buildHeaderCell(tr('pdf.description')),
                        _buildHeaderCell(tr('pdf.debit')),
                        _buildHeaderCell(tr('pdf.credit')),
                      ]
                    ),
                    ...entries.map((e) => pw.TableRow(
                      children: [
                        _buildCell(e['date'] ?? ''),
                        _buildCell(e['description'] ?? ''),
                        _buildCell(e['debit']?.toString() ?? '0'),
                        _buildCell(e['credit']?.toString() ?? '0'),
                      ]
                    )).toList(),
                  ]
                ),
              ]
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'statement_$accountName.pdf');
    } else {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    }
  }

  static Future<void> generateJournalEntryPdf({
    required Map<String, dynamic> entry,
    required List<Map<String, dynamic>> lines,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    pw.Font fontMedium;
    pw.Font fontBold;
    try {
      fontMedium = await PdfGoogleFonts.tajawalMedium();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      fontMedium = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(tr('pdf.journal_entry'),
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange800)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(company['name'] ?? '',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("${tr('pdf.entry_number')}: ${entry['id']}"),
                      ],
                    ),
                  ],
                ),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text("${tr('pdf.date')}: ${entry['date']}"),
                pw.Text("${tr('pdf.description')}: ${entry['description']}"),
                pw.SizedBox(height: 16),
                pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            _buildHeaderCell(tr('pdf.description')),
                            _buildHeaderCell(tr('pdf.debit')),
                            _buildHeaderCell(tr('pdf.credit')),
                            _buildHeaderCell(tr('pdf.memo')),
                          ]),
                      ...lines
                          .map((l) => pw.TableRow(children: [
                                _buildCell(l['account_name'] ?? 'غير محدد'),
                                _buildCell("${l['debit']}"),
                                _buildCell("${l['credit']}"),
                                _buildCell(l['memo'] ?? '-'),
                              ]))
                          .toList(),
                    ]),
              ],
            ),
          )
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'journal_entry_${entry['id']}');
  }

  /// Generates a Receipt or Payment Voucher (سند قبض / صرف)
  static Future<void> generateReceiptPdf({
    required Map<String, dynamic> receipt,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    final fontMedium = await PdfGoogleFonts.tajawalMedium();
    final fontBold = await PdfGoogleFonts.tajawalBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500, width: 2)),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(receipt['type'] == 'receipt' ? "سند قبض" : "سند صرف", 
                           style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(company['name'] ?? '', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text("رقم السند: ${receipt['id']}"),
                        pw.Text("التاريخ: ${receipt['date']}"),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),
                _buildInfoField("استلمنا من السيد / السادة:", receipt['received_from'] ?? ''),
                _buildInfoField("مبلغ وقدره:", "${receipt['amount']} ${company['currency']}"),
                _buildInfoField("وذلك مقابل:", receipt['description'] ?? ''),
                _buildInfoField("كتابةً:", Tafqeet.convert(receipt['amount'] as double, currency: company['currency'] ?? 'ريال')),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [pw.Text("توقيع المحاسب"), pw.SizedBox(height: 30), pw.Text("......................")]),
                    pw.Column(children: [pw.Text("توقيع المستلم"), pw.SizedBox(height: 30), pw.Text("......................")]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'receipt_${receipt['id']}');
  }

  /// Generates a Professional Salary Slip (مسير راتب)
  static Future<void> generatePayslipPdf({
    required Map<String, dynamic> employee,
    required Map<String, dynamic> slip,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    final fontMedium = await PdfGoogleFonts.tajawalMedium();
    final fontBold = await PdfGoogleFonts.tajawalBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Text("مسير راتب شهر: ${slip['month']} - ${slip['year']}", 
                     style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.grey100,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("الموظف: ${employee['name']}"),
                    pw.Text("الرقم الوظيفي: ${employee['id']}"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildValueTable("الاستحقاقات (Earnings)", {
                      "الراتب الأساسي": slip['basic_salary'],
                      "البدلات": slip['allowances'],
                      "الإضافي": slip['overtime'],
                    }),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: _buildValueTable("الاستقطاعات (Deductions)", {
                      "تأمينات": slip['insurance'],
                      "سلف": slip['loans'],
                      "غياب": slip['absent_penalty'],
                    }, isDeduction: true),
                  ),
                ],
              ),
              pw.Divider(),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                color: PdfColors.green50,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("صافي الراتب (Net Salary)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("${slip['net_salary']} ${company['currency']}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'payslip_${employee['name']}');
  }

  /// Generates a Professional Bilingual Employment Contract
  static Future<void> generateContractPdf({
    required Map<String, dynamic> employee,
    required Map<String, dynamic> contract,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    final fontMedium = await PdfGoogleFonts.tajawalMedium();
    final fontBold = await PdfGoogleFonts.tajawalBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text("عقد عمل (Employment Contract)", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("الطرف الأول: ${company['name']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("First Party (Employer)", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("الطرف الثاني: ${employee['name']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Second Party (Employee)", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                _buildContractClause("١. المسمى الوظيفي (Job Title)", "يعمل الطرف الثاني لدى الطرف الأول بمهنة (${employee['job_title']}).", "The Second Party shall work for the First Party in the capacity of (${employee['job_title']})."),
                _buildContractClause("٢. مدة العقد (Contract Duration)", "يبدأ هذا العقد من تاريخ ${contract['start_date']} وينتهي في ${contract['end_date'] ?? 'غير محدد'}.", "This contract starts on ${contract['start_date']} and ends on ${contract['end_date'] ?? 'Indefinite'}."),
                _buildContractClause("٣. الأجر (Remuneration)", "يستحق الطرف الثاني راتباً أساسياً قدره (${employee['basic_salary']} ${company['currency']}) بالإضافة للبدلات المتفق عليها.", "The Second Party is entitled to a basic salary of (${employee['basic_salary']} ${company['currency']}) plus agreed allowances."),
                _buildContractClause("٤. الالتزامات (Obligations)", "يلتزم الطرف الثاني بأداء العمل الموكل إليه ويفوض الطرف الأول بالاطلاع على اللوائح الداخلية.", "The Second Party commits to performing tasks assigned and follows internal regulations."),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(children: [pw.Text("توقيع الطرف الأول"), pw.SizedBox(height: 30), pw.Text("......................")]),
                    pw.Column(children: [pw.Text("توقيع الطرف الثاني"), pw.SizedBox(height: 30), pw.Text("......................")]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'contract_${employee['name']}');
  }

  static Future<void> generateWalletReportPdf({
    required List<Map<String, dynamic>> accounts,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    final fontMedium = await PdfGoogleFonts.tajawalMedium();
    final fontBold = await PdfGoogleFonts.tajawalBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(company['name'] ?? '', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(tr('wallet.title'), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  ],
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                      children: [
                        _buildHeaderCell(tr('accounting.code')),
                        _buildHeaderCell(tr('common.name')),
                        _buildHeaderCell(tr('wallet.bank_name')),
                        _buildHeaderCell(tr('accounting.balance')),
                      ],
                    ),
                    ...accounts.map((a) => pw.TableRow(
                      children: [
                        _buildCell(a['code'] ?? ''),
                        _buildCell(a['name'] ?? ''),
                        _buildCell(a['bank_name'] ?? '-'),
                        _buildCell("${a['balance']} ${company['currency']}", isBold: true),
                      ],
                    )).toList(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'wallet_summary');
  }

  static Future<void> generateSalarySlipPdf({
    required Map<String, dynamic> slip,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    
    pw.Font fontMedium;
    pw.Font fontBold;
    try {
      fontMedium = await PdfGoogleFonts.tajawalMedium();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      fontMedium = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(company['name'] ?? 'Hisabati ERP', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                      pw.Text(company['address'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(tr('pdf.salary_slip'), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text("${slip['month']}", style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.orange200),
              pw.SizedBox(height: 20),

              // Employee Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("${tr('hr.employee')}: ${slip['employee_name']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Text("${tr('hr.id')}: ${slip['employee_id']}", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("${tr('hr.job_title')}: ${slip['job_title'] ?? 'N/A'}", style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("${tr('pdf.issue_date')}: ${DateTime.now().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Earnings and Deductions Table
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Earnings
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(6),
                          color: PdfColors.green100,
                          child: pw.Text(tr('pdf.earnings'), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        _buildSlipRow(tr('hr.basic'), "${slip['basic_salary']}"),
                        _buildSlipRow(tr('hr.housing_allowance'), "${slip['housing_allowance']}"),
                        _buildSlipRow(tr('hr.transport_allowance'), "${slip['transport_allowance']}"),
                        _buildSlipRow(tr('hr.other_allowance'), "${slip['overtime'] ?? 0}"),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Deductions
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(6),
                          color: PdfColors.red100,
                          child: pw.Text(tr('pdf.deductions'), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        _buildSlipRow(tr('hr.social_insurance'), "${slip['insurance_deduction'] ?? 0}"),
                        _buildSlipRow(tr('hr.tax'), "${slip['tax_deduction'] ?? 0}"),
                        _buildSlipRow(tr('hr.loans'), "${slip['loan_deduction'] ?? 0}"),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Summary
              pw.Divider(),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(color: PdfColors.blue50),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(tr('hr.net_salary'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text("${slip['net_salary']} ${company['currency'] ?? 'SAR'}", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(Tafqeet.convert(slip['net_salary'], currency: company['currency'] ?? 'ريال'), 
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              
              pw.SizedBox(height: 50),
              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [pw.Text(tr('hr.employer_sig')), pw.SizedBox(height: 30), pw.Text("......................")]),
                  pw.Column(children: [pw.Text(tr('hr.employee_sig')), pw.SizedBox(height: 30), pw.Text("......................")]),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'salary_slip_${slip['employee_name']}');
  }

  static Future<void> generateMonthlyPayrollReportPdf({
    required List<Map<String, dynamic>> slips,
    required String month,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    final fontMedium = await PdfGoogleFonts.tajawalMedium();
    final fontBold = await PdfGoogleFonts.tajawalBold();

    double totalNet = slips.fold(0.0, (sum, item) => sum + (item['net_salary'] as num).toDouble());
    double totalDeductions = slips.fold(0.0, (sum, item) => sum + ((item['tax_deduction'] ?? 0) + (item['insurance_deduction'] ?? 0) + (item['loan_deduction'] ?? 0)));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(company['name'] ?? '', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${tr('hr.payroll_title')} - $month", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildHeaderCell(tr('hr.employee')),
                        _buildHeaderCell(tr('hr.basic')),
                        _buildHeaderCell(tr('pdf.earnings')),
                        _buildHeaderCell(tr('pdf.deductions')),
                        _buildHeaderCell(tr('hr.net_salary')),
                      ],
                    ),
                    ...slips.map((s) => pw.TableRow(
                      children: [
                        _buildCell(s['employee_name'] ?? ''),
                        _buildCell("${s['basic_salary']}"),
                        _buildCell("${(s['housing_allowance'] ?? 0) + (s['transport_allowance'] ?? 0)}"),
                        _buildCell("${(s['tax_deduction'] ?? 0) + (s['insurance_deduction'] ?? 0) + (s['loan_deduction'] ?? 0)}"),
                        _buildCell("${s['net_salary']}", isBold: true),
                      ],
                    )).toList(),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      child: pw.Column(
                        children: [
                          _buildSummaryRow(tr('hr.total_payroll'), "${_formatCurrency(totalNet)} ${company['currency']}"),
                          _buildSummaryRow(tr('hr.deductions'), "${_formatCurrency(totalDeductions)} ${company['currency']}"),
                          pw.Divider(),
                          _buildSummaryRow(tr('hr.total_net'), "${_formatCurrency(totalNet)} ${company['currency']}", isTotal: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'payroll_report_$month');
  }

  static pw.Widget _buildSlipRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildContractClause(String title, String ar, String en) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.Row(
             children: [
                pw.Expanded(child: pw.Text(ar, style: const pw.TextStyle(fontSize: 10))),
                pw.SizedBox(width: 20),
                pw.Expanded(child: pw.Text(en, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic), textAlign: pw.TextAlign.left)),
             ]
          )
        ],
      ),
    );
  }

  static pw.Widget _buildInfoField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Container(
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildValueTable(String title, Map<String, dynamic> data, {bool isDeduction = false}) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          color: isDeduction ? PdfColors.red100 : PdfColors.blue100,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(title, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
        ),
        ...data.entries.map((e) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e.key, style: const pw.TextStyle(fontSize: 9)),
              pw.Text("${e.value}", style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        )),
      ],
    );
  }

  static String _formatCurrency(double amount) {
    String str = amount.toStringAsFixed(2);
    List<String> parts = str.split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    parts[0] = parts[0].replaceAllMapped(reg, (Match m) => '${m[1]},');
    return parts.join('.');
  }

  static String _getFriendlyLabel(String key) {
    switch (key) {
      case 'revenue': return tr('ceo.metrics.revenue');
      case 'cogs': return tr('inventory.cogs'); // Assuming this key exists or similar
      case 'gross_profit': return tr('ceo.metrics.profit');
      case 'net_profit': return tr('ceo.metrics.profit');
      default: return key;
    }
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(text, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)));
  }

  static pw.Widget _buildCell(String text, {bool isBold = false}) {
    return pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(text, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)));
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: isTotal ? 12 : 10, fontWeight: isTotal ? pw.FontWeight.bold : null)),
          pw.Text(label, style: pw.TextStyle(fontSize: isTotal ? 12 : 10, fontWeight: isTotal ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfHeader(Map<String, dynamic> company, String title, pw.Font font) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(company['name'] ?? '', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: font)),
            pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: font, color: PdfColors.indigo900)),
          ],
        ),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static Future<void> generateAuditReportPdf({
    required List<Map<String, dynamic>> auditTrail,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    
    pw.Font fontMedium;
    pw.Font fontBold;
    try {
      fontMedium = await PdfGoogleFonts.tajawalMedium();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      fontMedium = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold, fontFallback: [fontMedium]),
        textDirection: pw.TextDirection.rtl,
        header: (context) => _buildPdfHeader(company, tr('compliance.audit_trail'), fontBold),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              tr('hr.id'),
              tr('common.date'),
              tr('common.description'),
              tr('hr.employee'),
              tr('common.type'),
            ],
            data: auditTrail.map((a) => [
              a['id'].toString(),
              a['timestamp'].toString().substring(0, 16),
              a['action'].toString(),
              a['user_id'] ?? 'System',
              a['entity_type'] ?? '',
            ]).toList(),
            headerStyle: pw.TextStyle(font: fontBold, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/audit_report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
