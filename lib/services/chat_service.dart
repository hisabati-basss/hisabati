import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String? attachmentUrl;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.attachmentUrl,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? 'Unknown',
      text: map['content'] ?? '',
      attachmentUrl: map['attachment_url'],
      timestamp: map['created_at'] != null 
          ? DateTime.parse(map['created_at']).toLocal() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': text,
      'attachment_url': attachmentUrl,
      'created_at': timestamp.toUtc().toIso8601String(),
    };
  }
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Stream<List<ChatMessage>> getChatStream() {
    return _supabase
        .from('employee_chats')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .map((data) => data.map((m) => ChatMessage.fromMap(m)).toList());
  }

  Future<void> sendMessage(String text, {
    required String senderId, 
    required String senderName,
    String? attachmentUrl,
  }) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      attachmentUrl: attachmentUrl,
      timestamp: DateTime.now(),
    );

    try {
      await _supabase.from('employee_chats').insert(msg.toMap());
    } catch (e) {
      debugPrint("Chat Send Error: $e");
    }
  }
}
