import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'supabase_service.dart';
import 'database_helper.dart';

enum SyncStatus { idle, syncing, success, error, offline }

/// SQLite ? Supabase Incremental Dirty-Bit Sync Engine
/// Replaces the old Isar-based sync with direct SQLite queries.
class SyncService with ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SupabaseService _supabaseService = SupabaseService();

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  String _lastSyncInfo = "?? ??? ???????? ???";
  String get lastSyncInfo => _lastSyncInfo;

  Timer? _autoSyncTimer;

  SyncService._internal() {
    _startAutoSync();
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => performIncrementalSync(),
    );
  }

  /// Core sync tables that mirror Supabase schema
  static const List<String> _syncTables = [
    'companies',
    'clients',
    'items',
    'invoices',
    'invoice_lines',
    'purchase_invoices',
    'purchase_invoice_lines',
    'journal_entries',
    'journal_entry_lines',
    'accounts',
    'employees',
    'salary_payments',
    'salary_slips',
    'attendance_logs',
    'leave_requests',
    'employee_loans',
    'suppliers',
    'payments',
    'cost_centers',
    'projects',
    'budgets',
    'assets',
    'asset_depreciation_logs',
    'warehouses',
    'inventory_batches',
    'inventory_transfers',
    'bom',
    'bom_lines',
    'manufacturing_orders',
    'cheques',
    'financial_custodies',
    'asset_custody_logs',
    'money_transfers',
    'real_estate_units',
    'real_estate_contracts',
    'investments',
    'investment_transactions',
    'sales_targets',
    'commissions',
    'job_applications',
    'system_users',
    'roles',
    'security_audit',
    'performance_reviews',
    'employee_contracts',
    'currency_rates',
    'fiscal_years',
    'recurring_transactions',
    'quotations',
    'quotation_lines',
    'receipt_vouchers',
    'payment_vouchers',
    'credit_notes',
  ];

  /// Columns that exist only in local SQLite but not in Supabase.
  /// These must be stripped before uploading to avoid PostgrestException.
  static const Map<String, List<String>> _localOnlyColumns = {
    'items': ['amount'],
    'companies': ['is_multi_branch'],
    'journal_entries': ['branch_id'],
    'journal_entry_lines': ['branch_id'],
    'purchase_invoices': ['branch_id'],
    'system_users': ['branch_id'],
    'cost_centers': ['branch_id'],
    'budgets': ['branch_id'],
    'invoices': ['branch_id'],
  };

  /// Performs incremental sync: pushes dirty records to Supabase,
  /// then pulls remote changes.
  Future<void> performIncrementalSync() async {
    if (_status == SyncStatus.syncing) return;

    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final String deviceId = await _dbHelper.getDeviceFingerprint();
      final String lastSync = await _dbHelper.getLastSyncTimestamp();

      final currentCompanyContext = await _dbHelper.getCurrentCompanyContext();
      final String currentCompanyId = currentCompanyContext?['company_id'] ?? 'default_company';

      // UPLOAD: Push all dirty records (sync_status = 0) to Supabase
      // Process in batches of 5 to avoid overwhelming the connection
      for (int i = 0; i < _syncTables.length; i += 5) {
        final batch = _syncTables.sublist(i, i + 5 > _syncTables.length ? _syncTables.length : i + 5);
        await Future.wait(batch.map((table) async {
          try {
            // Safety: verify the table has a sync_status column before querying
            final tableInfo = await db.rawQuery('PRAGMA table_info($table)');
            final columns = tableInfo.map((c) => c['name'] as String).toSet();
            if (!columns.contains('sync_status')) {
              return;
            }

            final dirtyRecords = await db.query(
              table,
              where: 'sync_status = ? AND (is_deleted IS NULL OR is_deleted = 0)',
              whereArgs: [0],
            );

            if (dirtyRecords.isNotEmpty) {
              final cleanRecords = dirtyRecords.map((r) {
                final clean = Map<String, dynamic>.from(r);
                clean.remove('sync_status');
                // Remove local-only columns that don't exist in Supabase
                final localOnly = _localOnlyColumns[table];
                if (localOnly != null) {
                  for (final col in localOnly) {
                    clean.remove(col);
                  }
                }
                if (table != 'companies' && table != 'system_users' && table != 'sync_queue') {
                   clean['company_id'] = currentCompanyId;
                }
                return clean;
              }).toList();

              await _supabaseService.upsertRecords(table, cleanRecords).timeout(const Duration(seconds: 15));

              // Mark as synced locally
              for (final record in dirtyRecords) {
                if (record['id'] != null) {
                  await db.update(
                    table,
                    {'sync_status': 1},
                    where: 'id = ?',
                    whereArgs: [record['id']],
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('Sync upload error for $table: $e');
          }
        }));
      }

      // DOWNLOAD: Pull remote changes since last sync
      // Process in batches of 8 to speed up initial sync significantly
      for (int i = 0; i < _syncTables.length; i += 8) {
        final batch = _syncTables.sublist(i, i + 8 > _syncTables.length ? _syncTables.length : i + 8);
        await Future.wait(batch.map((table) async {
          try {
            final isGlobalTable = table == 'companies' || table == 'system_users';
            final tablesWithCreatedAtOnly = ['currency_rates', 'fiscal_years', 'quotation_lines'];
            final remoteUpdates = await _supabaseService.fetchUpdates(
              table,
              lastSync,
              deviceId,
              companyId: isGlobalTable ? null : currentCompanyId,
              timestampColumn: tablesWithCreatedAtOnly.contains(table) ? 'created_at' : 'updated_at',
            ).timeout(const Duration(seconds: 15));

            if (remoteUpdates.isNotEmpty) {
              for (final remote in remoteUpdates) {
                final localRecord = Map<String, dynamic>.from(remote);
                // Remove remote company_id before inserting locally as SQLite schema might not have it
                if (!isGlobalTable) {
                  localRecord.remove('company_id');
                }
                // Ensure table has sync columns before insertion
                await db.insert(
                  table,
                  {...localRecord, 'sync_status': 1},
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          } catch (e) {
            debugPrint('Sync download error for $table: $e');
          }
        }));
      }

      // Update last sync timestamp
      await _dbHelper.setLastSyncTimestamp(DateTime.now().toIso8601String());

      _status = SyncStatus.success;
      _lastSyncInfo =
          "??? ??????: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    } catch (e) {
      _status = SyncStatus.error;
      _lastSyncInfo = "??? ?? ????????";
      debugPrint('Sync Error: $e');
    } finally {
      await refreshPendingCount();
      notifyListeners();
      Future.delayed(const Duration(seconds: 5), () {
        if (_status != SyncStatus.syncing) {
          _status = SyncStatus.idle;
          notifyListeners();
        }
      });
    }
  }

  Future<void> syncNow() => performIncrementalSync();

  Future<void> performFullSync() => performIncrementalSync();

  Future<void> refreshPendingCount() async {
    try {
      final db = await _dbHelper.database;
      int total = 0;
      for (final table in _syncTables) {
        try {
          final res = await db.rawQuery(
            'SELECT COUNT(*) as c FROM $table WHERE sync_status = 0',
          );
          total += (res.first['c'] as int? ?? 0);
        } catch (_) {}
      }
      _pendingCount = total;
    } catch (_) {
      _pendingCount = 0;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
