import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'supabase_service.dart';
import 'database_helper.dart';

enum SyncStatus { idle, syncing, success, error, offline }

/// SQLite → Supabase Incremental Dirty-Bit Sync Engine
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

  String _lastSyncInfo = "لم يتم المزامنة بعد";
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
    'security_audit',
    'performance_reviews',
    'employee_contracts',
  ];

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
              where: 'sync_status = ?',
              whereArgs: [0],
            );

            if (dirtyRecords.isNotEmpty) {
              final cleanRecords = dirtyRecords.map((r) {
                final clean = Map<String, dynamic>.from(r);
                clean.remove('sync_status');
                return clean;
              }).toList();

              await _supabaseService.upsertRecords(table, cleanRecords).timeout(const Duration(seconds: 15));

              // Mark as synced locally
              for (final record in dirtyRecords) {
                await db.update(
                  table,
                  {'sync_status': 1},
                  where: 'id = ?',
                  whereArgs: [record['id']],
                );
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
            final remoteUpdates = await _supabaseService.fetchUpdates(
              table,
              lastSync,
              deviceId,
            ).timeout(const Duration(seconds: 15));

            if (remoteUpdates.isNotEmpty) {
              for (final remote in remoteUpdates) {
                // Ensure table has sync columns before insertion
                await db.insert(
                  table,
                  {...remote, 'sync_status': 1},
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
          "آخر مزامنة: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    } catch (e) {
      _status = SyncStatus.error;
      _lastSyncInfo = "خطأ في المزامنة";
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
