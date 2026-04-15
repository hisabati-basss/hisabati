import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  /// Upsert multiple records to a specific table in Supabase.
  /// Standardizes records by ensuring sync-related metadata is consistent.
  Future<void> upsertRecords(String tableName, List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return;
    
    // Filter out SQLite specific local-only keys if any (like local rowid)
    // Supabase will use the 'id' (UUID) as the primary key.
    
    await _supabase.from(tableName).upsert(records, onConflict: 'id');
  }

  /// Fetch all updates since a specific timestamp across all devices EXCEPT the current one.
  Future<List<Map<String, dynamic>>> fetchUpdates(String tableName, String since, String localDeviceId) async {
    final response = await _supabase
        .from(tableName)
        .select()
        .gt('updated_at', since)
        .neq('device_id', localDeviceId);
        
    return List<Map<String, dynamic>>.from(response);
  }

  /// Upload a file to a specific storage bucket.
  Future<String?> uploadFile({
    required String bucketName,
    required String filePath,
    required String fileName,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    try {
      final String path = await _supabase.storage.from(bucketName).upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      // Get Public URL
      final String publicUrl = _supabase.storage.from(bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Supabase Storage Error: $e');
      return null;
    }
  }

  /// Get the server-side time (if possible, otherwise use local as fallback for conflict resolution)
  /// Note: Supabase handles 'now' via triggers if needed, but for 'Last Write Wins',
  /// we rely on the device's ISO string which is already in our SQLite.
}
