import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';

class BackupService {
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  /// Creates a local backup of the SQLite database in the Documents/Hisabati_Backups folder.
  /// Returns the path to the backup file.
  static Future<String?> createBackup() async {
    try {
      final dbPath = await DatabaseHelper().getDatabasePath();
      final backupDir = await _getBackupDirectory();
      
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final backupPath = '${backupDir.path}/hisabati_backup_$timestamp.db';
      
      await File(dbPath).copy(backupPath);
      
      // Keep only last 7 backups for storage efficiency
      await _cleanOldBackups(backupDir);
      
      return backupPath;
    } catch (e) {
      debugPrint("🚨 Backup Error: $e");
      return null;
    }
  }

  /// Restores the database from a backup file (requires app restart for full effect)
  static Future<void> restoreBackup(String backupPath) async {
    final dbPath = await DatabaseHelper().getDatabasePath();
    await File(backupPath).copy(dbPath);
    // Note: The app should ideally be restarted here or the DB helper re-initialized 
  }

  /// Lists all available backups in the local storage
  static Future<List<FileSystemEntity>> listBackups() async {
    final backupDir = await _getBackupDirectory();
    if (!backupDir.existsSync()) return [];
    return backupDir.listSync().where((f) => f.path.endsWith('.db')).toList();
  }

  static Future<Directory> _getBackupDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docDir.path}/Hisabati_Backups');
    if (!backupDir.existsSync()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  static Future<void> _cleanOldBackups(Directory dir) async {
    final backups = dir.listSync().where((f) => f.path.endsWith('.db')).toList();
    backups.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    
    if (backups.length > 7) {
      final toDelete = backups.sublist(0, backups.length - 7);
      for (var f in toDelete) {
        await f.delete();
      }
    }
  }
}

