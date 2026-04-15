// lib/core/accounting/accounting_engine.dart
// Unified Accounting Engine - SQLite based (QuickBooks-grade double-entry)
import '../../services/database_helper.dart';
import 'package:uuid/uuid.dart';

class AccountingEngine {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  /// Process a complete sales transaction with double-entry journal
  Future<bool> processSale({
    required String clientId,
    required String clientName,
    required List<Map<String, dynamic>> cartItems,
    required String paymentType, // cash, credit, bank
    String? paymentAccountId,
    String? projectId,
    String? costCenterId,
  }) async {
    try {
      double subtotal = 0;
      double totalTax = 0;
      double totalCogs = 0;
      final List<Map<String, dynamic>> lines = [];

      for (var item in cartItems) {
        double qty = (item['quantity'] as num).toDouble();
        double price = (item['price'] as num).toDouble();
        double lineTotal = qty * price;
        double lineTax = (item['tax_amount'] as num?)?.toDouble() ?? (lineTotal * 0.15);
        double unitCost = (item['cost_price'] as num?)?.toDouble() ?? 0;

        subtotal += lineTotal;
        totalTax += lineTax;
        totalCogs += unitCost * qty;

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
          'project_id': projectId,
        },
        lines: lines.map((l) => {...l, 'invoice_id': invoiceId}).toList(),
        paymentAccountId: paymentAccountId,
      );

      // --- INVENTORY INTEGRATION (QuickBooks Style) ---
      final db = await _db.database;
      await db.transaction((txn) async {
        final nowStr = DateTime.now().toIso8601String();
        for (var item in cartItems) {
          final itemId = item['item_id'] ?? item['id'];
          final qty = (item['quantity'] as num).toDouble();
          
          // 1. Deduct from Items
          await txn.rawUpdate(
            'UPDATE items SET quantity = quantity - ? WHERE id = ?',
            [qty, itemId]
          );

          // 2. Record Inventory Transaction
          await txn.insert('inventory_transactions', {
            'id': _uuid.v4(),
            'item_id': itemId,
            'item_name': item['name'],
            'type': 'sale',
            'quantity': -qty, // Negative for deduction
            'reference_id': invoiceId,
            'date': nowStr,
            'created_at': nowStr,
            'updated_at': nowStr,
            'sync_status': 0
          });
        }

        // 3. Post COGS Entry (if totalCogs > 0)
        if (totalCogs > 0) {
          final cogsEntryId = 'JE_COGS_$invoiceId';
          await txn.insert('journal_entries', {
            'id': cogsEntryId,
            'date': nowStr.split('T')[0],
            'description': "قيد تكلفة البضاعة المباعة للفاتورة $invoiceId",
            'reference_id': invoiceId,
          });

          // Debit COGS Expense
          await txn.insert('journal_entry_lines', {
            'id': "${cogsEntryId}_L1", 'entry_id': cogsEntryId, 'account_id': 'ACC_COGS', 'debit': totalCogs, 'credit': 0.0,
          });
          // Credit Inventory Asset
          await txn.insert('journal_entry_lines', {
            'id': "${cogsEntryId}_L2", 'entry_id': cogsEntryId, 'account_id': 'ACC_INVENTORY', 'debit': 0.0, 'credit': totalCogs,
          });

          // Update Account Balances
          await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [totalCogs, 'ACC_COGS']);
          await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [totalCogs, 'ACC_INVENTORY']);
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Process purchase with double-entry journal
  Future<bool> processPurchase({
    required String supplierId,
    required List<Map<String, dynamic>> purchaseItems,
    required String paymentType,
    String? paymentAccountId,
    String? projectId,
    String? costCenterId,
    String? attachmentPath,
  }) async {
    try {
      double total = 0;
      final List<Map<String, dynamic>> lines = [];

      for (var item in purchaseItems) {
        double qty = (item['quantity'] as num).toDouble();
        double price = (item['price'] as num).toDouble();
        total += qty * price;

        lines.add({
          'item_id': item['item_id'],
          'name': item['name'],
          'quantity': qty,
          'price': price,
        });
      }

      await _db.savePurchaseInvoice(
        supplierId: supplierId,
        total: total,
        paymentType: paymentType,
        lines: lines,
        paymentAccountId: paymentAccountId,
        projectId: projectId,
        costCenterId: costCenterId,
        attachmentPath: attachmentPath,
      );

      // --- INVENTORY & COSTING (QuickBooks Style) ---
      final db = await _db.database;
      await db.transaction((txn) async {
        final nowStr = DateTime.now().toIso8601String();
        for (var item in purchaseItems) {
          final itemId = item['item_id'];
          final qtyPurchased = (item['quantity'] as num).toDouble();
          final pricePurchased = (item['price'] as num).toDouble();

          // 1. Get current stock and cost for Weighted Average calculation
          final current = await txn.query('items', columns: ['quantity', 'cost_price'], where: 'id = ?', whereArgs: [itemId]);
          if (current.isNotEmpty) {
            double oldQty = (current.first['quantity'] as num?)?.toDouble() ?? 0;
            double oldCost = (current.first['cost_price'] as num?)?.toDouble() ?? 0;
            
            // 2. Calculate Weighted Average Cost (WAC)
            double newQty = oldQty + qtyPurchased;
            double newCost = oldCost;
            if (newQty > 0) {
              newCost = ((oldQty * oldCost) + (qtyPurchased * pricePurchased)) / newQty;
            }

            // 3. Update Item Stock and Cost
            await txn.rawUpdate(
              'UPDATE items SET quantity = ?, cost_price = ? WHERE id = ?',
              [newQty, newCost, itemId]
            );

            // 4. Record Inventory Transaction
            await txn.insert('inventory_transactions', {
              'id': _uuid.v4(),
              'item_id': itemId,
              'item_name': item['name'],
              'type': 'purchase',
              'quantity': qtyPurchased,
              'reference_id': 'PUR_${DateTime.now().millisecondsSinceEpoch}',
              'date': nowStr,
              'created_at': nowStr,
              'updated_at': nowStr,
              'sync_status': 0
            });
          }
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Process manufacturing order - deduct raw materials, add finished goods
  Future<bool> processManufacturing({
    required String bomId,
    required double qtyToProduce,
  }) async {
    try {
      await _db.executeManufacturingOrder(
        bomId: bomId,
        qtyToProduce: qtyToProduce,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════
  // 📄 Quotations (عروض الأسعار)
  // Fixed pricing upon creation
  // ═══════════════════════════════════════════════════
  
  Future<String?> processQuotation({
    required String clientId,
    required String clientName,
    required List<Map<String, dynamic>> items,
    required String expiryDate,
    String? notes,
  }) async {
    try {
      double subtotal = 0;
      double totalTax = 0;
      final List<Map<String, dynamic>> lines = [];

      for (var item in items) {
        double qty = (item['quantity'] as num).toDouble();
        double price = (item['price'] as num).toDouble(); // Snapshot fixed price
        double lineTotal = qty * price;
        double lineTax = (item['tax_amount'] as num?)?.toDouble() ?? (lineTotal * 0.15); // Default 15% VAT

        subtotal += lineTotal;
        totalTax += lineTax;

        lines.add({
          'id': 'QL_${_uuid.v4().substring(0, 8)}',
          'item_id': item['item_id'] ?? item['id'],
          'name': item['name'],
          'quantity': qty,
          'price': price,
          'tax_rate': lineTax / lineTotal,
          'total': lineTotal + lineTax,
        });
      }

      final quotationId = 'QUO_${DateTime.now().millisecondsSinceEpoch}';
      final total = subtotal + totalTax;

      await _db.addQuotation({
        'id': quotationId,
        'client_id': clientId,
        'client_name': clientName,
        'issue_date': DateTime.now().toIso8601String(),
        'expiry_date': expiryDate,
        'subtotal': subtotal,
        'tax_amount': totalTax,
        'total': total,
        'status': 'draft',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      }, lines.map((l) => {...l, 'quotation_id': quotationId}).toList());

      return quotationId;
    } catch (e) {
      return null;
    }
  }

  /// Convert a Quotation to a Sales Invoice carrying over the exact locked prices
  Future<bool> convertQuotationToInvoice(String quotationId, String paymentType) async {
    try {
      final db = await _db.database;
      final quoResp = await db.query('quotations', where: 'id = ?', whereArgs: [quotationId]);
      if (quoResp.isEmpty) return false;
      
      final quote = quoResp.first;
      final linesResp = await db.query('quotation_lines', where: 'quotation_id = ?', whereArgs: [quotationId]);
      
      // Map to the format `processSale` expects
      List<Map<String, dynamic>> cartItems = linesResp.map((l) => {
        'name': l['name'],
        'quantity': l['quantity'],
        'price': l['price'],
        'tax_amount': ((l['total'] as num) - ((l['price'] as num) * (l['quantity'] as num))),
      }).toList();

      // Creates the actual sale and journal entries
      final res = await processSale(
        clientId: quote['client_id']?.toString() ?? 'CASH_CLIENT',
        clientName: quote['client_name']?.toString() ?? 'عميل نقدي',
        cartItems: cartItems,
        paymentType: paymentType,
      );

      if (res) {
        // Technically we should retrieve the generated invoice_id, but here processSale doesn't return it natively yet.
        // For now, we just mark it as converted with a generic reference.
        await _db.convertQuotationToInvoice(quotationId, "INV_FROM_QUO");
      }
      return res;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════
  // 💸 Vouchers (سندات القبض والدفع)
  // Double-entry included
  // ═══════════════════════════════════════════════════

  /// سند قبض - استلام نقدية 
  /// Debit Cash/Bank, Credit AR
  Future<bool> processReceiptVoucher({
    required String clientId,
    required String clientName,
    required double amount,
    required String paymentMethod, // cash, bank
    String? bankAccountId, // Required if bank
    String? referenceInvoiceId,
    String? notes,
  }) async {
    try {
      final voucherId = 'RV_${DateTime.now().millisecondsSinceEpoch}';
      final entryId = 'JE_$voucherId';
      final String debitAccount = paymentMethod == 'bank' ? (bankAccountId ?? 'ACC_BANK') : 'ACC_CASH';
      final String creditAccount = 'ACC_RECEIVABLE';

      final db = await _db.database;
      await db.transaction((txn) async {
        final nowStr = DateTime.now().toIso8601String();
        // 1. Save Voucher
        await txn.insert('receipt_vouchers', {
          'id': voucherId,
          'client_id': clientId,
          'client_name': clientName,
          'amount': amount,
          'payment_method': paymentMethod,
          'bank_account_id': bankAccountId,
          'invoice_id': referenceInvoiceId,
          'date': nowStr,
          'notes': notes,
          'journal_entry_id': entryId,
          'created_at': nowStr,
        });

        // 2. Generate Journal Entry
        await txn.insert('journal_entries', {
          'id': entryId,
          'date': nowStr.split('T')[0],
          'description': "سند قبض رقم $voucherId من العميل $clientName",
          'reference_id': voucherId,
        });

        // Debit Bank/Cash
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': debitAccount, 'debit': amount, 'credit': 0.0,
        });
        // Credit AR
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L2", 'entry_id': entryId, 'account_id': creditAccount, 'debit': 0.0, 'credit': amount,
        });

        // 3. Update Balances
        await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [amount, debitAccount]);
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, creditAccount]);
        // Update client balance if clients table manages balances directly
        await txn.rawUpdate('UPDATE clients SET balance = balance - ? WHERE id = ?', [amount, clientId]);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// سند صرف - دفع للموردين
  /// Debit AP, Credit Cash/Bank
  Future<bool> processPaymentVoucher({
    required String supplierId,
    required String supplierName,
    required double amount,
    required String paymentMethod,
    String? bankAccountId,
    String? referenceInvoiceId,
    String? notes,
  }) async {
    try {
      final voucherId = 'PV_${DateTime.now().millisecondsSinceEpoch}';
      final entryId = 'JE_$voucherId';
      final String creditAccount = paymentMethod == 'bank' ? (bankAccountId ?? 'ACC_BANK') : 'ACC_CASH';
      final String debitAccount = 'ACC_PAYABLE';

      final db = await _db.database;
      await db.transaction((txn) async {
        final nowStr = DateTime.now().toIso8601String();
        // 1. Save Voucher
        await txn.insert('payment_vouchers', {
          'id': voucherId,
          'supplier_id': supplierId,
          'supplier_name': supplierName,
          'amount': amount,
          'payment_method': paymentMethod,
          'bank_account_id': bankAccountId,
          'invoice_id': referenceInvoiceId,
          'date': nowStr,
          'notes': notes,
          'journal_entry_id': entryId,
          'created_at': nowStr,
        });

        // 2. Generate Journal Entry
        await txn.insert('journal_entries', {
          'id': entryId,
          'date': nowStr.split('T')[0],
          'description': "سند صرف رقم $voucherId للمورد $supplierName",
          'reference_id': voucherId,
        });

        // Debit AP
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': debitAccount, 'debit': amount, 'credit': 0.0,
        });
        // Credit Cash/Bank
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L2", 'entry_id': entryId, 'account_id': creditAccount, 'debit': 0.0, 'credit': amount,
        });

        // 3. Update Balances
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, creditAccount]);
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, debitAccount]);
        await txn.rawUpdate('UPDATE suppliers SET balance = balance - ? WHERE id = ?', [amount, supplierId]);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════
  // 🔒 Fiscal Period Closing
  // Auto-transfer net profit/loss to Retained Earnings
  // ═══════════════════════════════════════════════════
  
  Future<bool> closeFiscalYear(String yearName, String startDate, String endDate) async {
    try {
      final db = await _db.database;
      
      // Calculate net profit/loss for the period
      final pnl = await _db.getPNLSummary(startDate, endDate);
      final netProfit = (pnl['net_profit'] as num?)?.toDouble() ?? 0.0;
      
      final fyId = 'FY_${DateTime.now().millisecondsSinceEpoch}';
      final entryId = 'JE_CL_$fyId';

      await db.transaction((txn) async {
        final nowStr = DateTime.now().toIso8601String();
        
        // 1. Register Fiscal Year as closed
        await txn.insert('fiscal_years', {
          'id': fyId,
          'name': yearName,
          'start_date': startDate,
          'end_date': endDate,
          'is_closed': 1,
          'closing_entry_id': entryId,
          'created_at': nowStr,
        });

        // 2. Create Closing Journal Entry
        await txn.insert('journal_entries', {
          'id': entryId,
          'date': endDate,
          'description': "إغلاق السنة المالية: $yearName وترحيل الأرباح",
          'reference_id': fyId,
        });

        // If profit > 0 (Debit Income Summary / Credit Retained Earnings)
        // Note: For simplicity, we directly hit Retained Earnings to offset the net difference of all PnL accounts
        if (netProfit > 0) {
           await txn.insert('journal_entry_lines', {
            'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': 'ACC_RETAINED_EARNINGS', 'debit': 0.0, 'credit': netProfit,
          });
        } else if (netProfit < 0) {
           await txn.insert('journal_entry_lines', {
            'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': 'ACC_RETAINED_EARNINGS', 'debit': netProfit.abs(), 'credit': 0.0,
          });
        }
        
        // Ensure Retained Earnings account exists or update it
        // The detailed closing of individual Expense/Revenue accounts to 0 is handled logically in real ERPs,
        // but updating our Retained earnings balance establishes the starting Equity for the new year.
        if (netProfit != 0) {
            await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [netProfit, 'ACC_RETAINED_EARNINGS']);
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════
  // 📝 Returns & Adjustments (Notes)
  // ═══════════════════════════════════════════════════

  /// إشعار دائن - مرتجع مبيعات
  /// Reverts a sale: Debit Revenue/VAT, Credit AR
  Future<bool> processCreditNote({
    required String invoiceId,
    required String clientId,
    required double amount,
    required String reason,
    required List<Map<String, dynamic>> items,
    bool returnToStock = true,
  }) async {
    try {
      final noteId = 'CN_${DateTime.now().millisecondsSinceEpoch}';
      final entryId = 'JE_$noteId';
      final db = await _db.database;

      await db.transaction((txn) async {
        final nowStr = DateTime.now().toIso8601String();
        
        // 1. Save Credit Note
        await txn.insert('credit_notes', {
          'id': noteId,
          'original_invoice_id': invoiceId,
          'client_id': clientId,
          'amount': amount,
          'reason': reason,
          'date': nowStr,
          'journal_entry_id': entryId,
          'status': 'posted',
          'created_at': nowStr,
          'updated_at': nowStr,
          'sync_status': 0
        });

        // 2. Generate Reverse Journal Entry
        await txn.insert('journal_entries', {
          'id': entryId,
          'date': nowStr.split('T')[0],
          'description': "إشعار دائن (مرتجع مبيعات) رقم $noteId للفاتورة $invoiceId",
          'reference_id': noteId,
        });

        // Logic: Reversing a standard sale (15% VAT assumed for simplicity here)
        double taxAmount = amount - (amount / 1.15);
        double netAmount = amount - taxAmount;

        // Debit Sales (Revenue Reduction)
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': 'ACC_SALES', 'debit': netAmount, 'credit': 0.0,
        });
        // Debit VAT Payable (Tax Reduction)
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L2", 'entry_id': entryId, 'account_id': 'ACC_VAT_PAYABLE', 'debit': taxAmount, 'credit': 0.0,
        });
        // Credit AR (Asset Reduction)
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L3", 'entry_id': entryId, 'account_id': 'ACC_RECEIVABLE', 'debit': 0.0, 'credit': amount,
        });

        // 3. Update Balances
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [netAmount, 'ACC_SALES']);
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [taxAmount, 'ACC_VAT_PAYABLE']);
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, 'ACC_RECEIVABLE']);
        await txn.rawUpdate('UPDATE clients SET balance = balance - ? WHERE id = ?', [amount, clientId]);

        // 4. Inventory Return
        if (returnToStock) {
          for (var item in items) {
            final itemId = item['item_id'];
            final qty = (item['quantity'] as num).toDouble();
            
            await txn.rawUpdate('UPDATE items SET quantity = quantity + ? WHERE id = ?', [qty, itemId]);
            await txn.insert('inventory_transactions', {
              'id': _uuid.v4(),
              'item_id': itemId,
              'item_name': item['name'],
              'type': 'return',
              'quantity': qty,
              'reference_id': noteId,
              'date': nowStr,
              'created_at': nowStr,
              'updated_at': nowStr,
              'sync_status': 0
            });
          }
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// إشعار مدين - مرتجع مشتريات
  /// Debit AP, Credit Purchases/VAT
  Future<bool> processDebitNote({
    required String originalPurchaseId,
    required String supplierId,
    required double amount,
    required String reason,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final noteId = 'DN_${DateTime.now().millisecondsSinceEpoch}';
      final entryId = 'JE_$noteId';
      final db = await _db.database;

      await db.transaction((txn) async {
        final nowStr = DateTime.now().toIso8601String();
        
        // 1. Save Debit Note
        await txn.insert('debit_notes', {
          'id': noteId,
          'original_purchase_id': originalPurchaseId,
          'supplier_id': supplierId,
          'amount': amount,
          'reason': reason,
          'date': nowStr,
          'journal_entry_id': entryId,
          'status': 'posted',
          'created_at': nowStr,
          'updated_at': nowStr,
          'sync_status': 0
        });

        // 2. Generate Journal Entry
        await txn.insert('journal_entries', {
          'id': entryId,
          'date': nowStr.split('T')[0],
          'description': "إشعار مدين (مرتجع مشتريات) رقم $noteId للمشتريات $originalPurchaseId",
          'reference_id': noteId,
        });

        double taxAmount = amount - (amount / 1.15);
        double netAmount = amount - taxAmount;

        // Debit AP (Liability Reduction)
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': 'ACC_PAYABLE', 'debit': amount, 'credit': 0.0,
        });
        // Credit Purchases/Inventory (Account determined by user, assuming inventory for SME)
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L2", 'entry_id': entryId, 'account_id': 'ACC_INVENTORY', 'debit': 0.0, 'credit': netAmount,
        });
        // Credit VAT Input (Tax Reduction)
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L3", 'entry_id': entryId, 'account_id': 'ACC_VAT_INPUT', 'debit': 0.0, 'credit': taxAmount,
        });

        // 3. Update Balances
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, 'ACC_PAYABLE']);
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [netAmount, 'ACC_INVENTORY']);
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [taxAmount, 'ACC_VAT_INPUT']);
        await txn.rawUpdate('UPDATE suppliers SET balance = balance - ? WHERE id = ?', [amount, supplierId]);

        // 4. Stock Adjustment
        for (var item in items) {
          final itemId = item['item_id'];
          final qty = (item['quantity'] as num).toDouble();
          await txn.rawUpdate('UPDATE items SET quantity = quantity - ? WHERE id = ?', [qty, itemId]);
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════
  // 🛒 Procurement (أوامر الشراء)
  // ═══════════════════════════════════════════════════

  Future<String?> processPurchaseOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    required String expectedDelivery,
    String? notes,
  }) async {
    try {
      final poId = 'PO_${DateTime.now().millisecondsSinceEpoch}';
      final db = await _db.database;
      
      double subtotal = 0;
      for (var item in items) {
        subtotal += (item['quantity'] as num) * (item['price'] as num);
      }
      double tax = subtotal * 0.15;

      await db.transaction((txn) async {
        final nowStr = DateTime.now().toIso8601String();
        await txn.insert('purchase_orders', {
          'id': poId,
          'supplier_id': supplierId,
          'issue_date': nowStr,
          'expected_delivery': expectedDelivery,
          'subtotal': subtotal,
          'tax_amount': tax,
          'total': subtotal + tax,
          'status': 'sent',
          'notes': notes,
          'created_at': nowStr,
          'updated_at': nowStr,
          'sync_status': 0
        });

        for (var item in items) {
          await txn.insert('purchase_order_lines', {
            'id': _uuid.v4(),
            'order_id': poId,
            'item_id': item['item_id'],
            'name': item['name'],
            'quantity': item['quantity'],
            'price': item['price'],
            'total': (item['quantity'] as num) * (item['price'] as num),
            'updated_at': nowStr,
            'sync_status': 0
          });
        }
      });
      return poId;
    } catch (e) {
      return null;
    }
  }

  Future<bool> convertPOToInvoice(String poId, String paymentType) async {
    try {
      final db = await _db.database;
      final poResp = await db.query('purchase_orders', where: 'id = ?', whereArgs: [poId]);
      if (poResp.isEmpty) return false;
      
      final po = poResp.first;
      final lines = await db.query('purchase_order_lines', where: 'order_id = ?', whereArgs: [poId]);
      
      final res = await processPurchase(
        supplierId: po['supplier_id'].toString(),
        purchaseItems: lines.map((l) => {
          'item_id': l['item_id'],
          'name': l['name'],
          'quantity': l['quantity'],
          'price': l['price'],
        }).toList(),
        paymentType: paymentType,
      );

      if (res) {
        await db.update('purchase_orders', {'status': 'received', 'converted_invoice_id': 'INV_PO_$poId'}, where: 'id = ?', whereArgs: [poId]);
      }
      return res;
    } catch (e) {
      return false;
    }
  }
}
