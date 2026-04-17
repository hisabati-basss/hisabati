import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'qr_service.dart';
import '../utils/tafqeet.dart';

class PdfService {
  /// Generates and previews a premium PDF invoice.
  static Future<void> generateInvoice({
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> company,
    bool isThermal = false,
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

    // 3. Load Developer Logo
    pw.ImageProvider? footerLogo;
    try {
      final ByteData data = await rootBundle.load('assets/image/HBASSS.png');
      footerLogo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}
    
    // Fetch Client Balance (To be linked with Isar Account logic later)
    final String clientId = invoice['client_id'] ?? 'CUST_DEMO';
    final double clientBalance = 0.0;
    
    // Determine Invoice Type
    final bool isCredit = invoice['payment_type'] == 'credit';
    final String titleText = isCredit 
        ? "${tr('pdf.tax_invoice')} - ${tr('pdf.credit')}" 
        : "${tr('pdf.tax_invoice')} (${tr('pdf.cash')})";

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
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold),
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
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold),
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
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold),
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
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold),
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
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold),
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
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold),
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
        theme: pw.ThemeData.withFont(base: fontMedium, bold: fontBold),
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
}
