// lib/features/sales/data/sales_repository.dart
// SQLite-based Sales Repository
import '../../../services/database_helper.dart';
import '../../../core/accounting/journal_dispatcher.dart';
import '../../../core/printing/pdf_generator.dart';
import 'package:uuid/uuid.dart';

class SalesRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final JournalDispatcher _dispatcher = JournalDispatcher();
  final PdfGenerator _pdfGenerator = PdfGenerator();
  final _uuid = const Uuid();

  Future<void> createInvoice({
    required String clientId,
    required String clientName,
    required List<Map<String, dynamic>> items,
    String paymentType = 'cash',
    String? paymentAccountId,
  }) async {
    double subtotal = 0;
    double totalTax = 0;
    final List<Map<String, dynamic>> lines = [];

    for (var item in items) {
      double qty = (item['quantity'] as num).toDouble();
      double price = (item['price'] as num).toDouble();
      double lineTotal = qty * price;
      double lineTax = lineTotal * 0.15;

      subtotal += lineTotal;
      totalTax += lineTax;

      lines.add({
        'id': 'IL_${_uuid.v4().substring(0, 8)}',
        'name': item['name'],
        'quantity': qty,
        'price_at_sale': price,
      });
    }

    final invoiceId = 'INV_${DateTime.now().millisecondsSinceEpoch}';
    final total = subtotal + totalTax;

    await _db.saveInvoiceWithLines(
      invoice: {
        'id': invoiceId,
        'issue_date': DateTime.now().toIso8601String(),
        'client_id': clientId,
        'subtotal': subtotal,
        'tax_amount': totalTax,
        'total': total,
        'status': 'posted',
        'payment_type': paymentType,
      },
      lines: lines.map((l) => {...l, 'invoice_id': invoiceId}).toList(),
      paymentAccountId: paymentAccountId,
    );
  }
}
