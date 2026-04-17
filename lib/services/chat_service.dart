import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

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

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? 'Unknown',
      text: map['content'] ?? '',
      timestamp: map['created_at'] != null 
          ? DateTime.parse(map['created_at']).toLocal() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channel_id': 'CH_GENERAL',
      'sender_id': senderId,
      'sender_name': senderName,
      'content': text,
      'created_at': timestamp.toIso8601String(),
      'is_task': 0
    };
  }
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal() {
    _startPolling();
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _uuid = const Uuid();
  final StreamController<List<ChatMessage>> _controller = StreamController<List<ChatMessage>>.broadcast();

  Timer? _pollingTimer;

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _refreshChat();
    });
  }

  Future<void> _refreshChat() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query('messages', 
        where: 'channel_id = ?', 
        whereArgs: ['CH_GENERAL'], 
        orderBy: 'created_at DESC', 
        limit: 100
      );
      final messages = results.map((m) => ChatMessage.fromMap(m)).toList();
      _controller.add(messages);
    } catch (e) {
      debugPrint("Chat Refresh Error: $e");
    }
  }

  Future<void> sendMessage(String text, {required String senderId, required String senderName}) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );

    try {
      final db = await _dbHelper.database;
      await db.insert('messages', msg.toMap());
      _refreshChat(); // Immediate refresh
    } catch (e) {
      debugPrint("Chat Send Error: $e");
    }
  }

  Stream<List<ChatMessage>> getChatStream() {
    _refreshChat(); // Initial load
    return _controller.stream;
  }

  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}
