import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? 'Unknown',
      text: json['text'] ?? '',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at']).toLocal() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'text': text,
      'created_at': timestamp.toUtc().toIso8601String(),
    };
  }
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  RealtimeChannel? _channel;

  /// Broadcast a message (No storage, pure realtime ping for high speed sync)
  Future<void> sendMessage(String text, {required String senderId, required String senderName}) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );

    try {
      // 1. Insert into Supabase Table 'internal_chat' for history
      await _supabase.from('internal_chat').insert(msg.toJson());
    } catch (e) {
      // Supabase table might not exist in dev, ignore for now
      print("SQL Error ignored for chat insert: $e");
    }

    // 2. Broadcast for instant UI feel without polling
    if (_channel != null) {
      await _channel!.sendBroadcastMessage(
        event: 'new_message',
        payload: msg.toJson(),
      );
    }
  }

  /// Listen to chat stream directly from DB (Postgres Changes)
  Stream<List<ChatMessage>> getChatStream() {
    return _supabase
        .from('internal_chat')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .map((maps) => maps.map((m) => ChatMessage.fromJson(m)).toList());
  }

  void dispose() {
    _channel?.unsubscribe();
  }
}
