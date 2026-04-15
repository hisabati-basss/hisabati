import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/chat_service.dart';
import '../theme/app_theme_extension.dart';

class EmployeeChatScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const EmployeeChatScreen({
    super.key, 
    this.currentUserId = 'EMP_1', 
    this.currentUserName = 'Current User'
  });

  @override
  State<EmployeeChatScreen> createState() => _EmployeeChatScreenState();
}

class _EmployeeChatScreenState extends State<EmployeeChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _msgController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    _focusNode.requestFocus();
    
    await _chatService.sendMessage(
      text, 
      senderId: widget.currentUserId, 
      senderName: widget.currentUserName
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Expanded Chat Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardSurface,
                borderRadius: BorderRadius.circular(context.cardRadius),
                border: Border.all(color: context.cardBorder),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: context.cardBorder)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_alt, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('internal_hub.general_chat'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.headerSize, color: context.textColor)),
                            Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.green, size: 8),
                                const SizedBox(width: 4),
                                Text(tr('internal_hub.online_now'), style: TextStyle(color: Colors.green, fontSize: context.bodySize - 2)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Messages Stream
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _chatService.getChatStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              tr('common.error') + ': ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final messages = snapshot.data ?? [];
                        if (messages.isEmpty) {
                          return Center(
                            child: Text(
                              tr('chat.no_messages'),
                              style: TextStyle(color: context.mutedText),
                            ),
                          );
                        }

                        return ListView.builder(
                          reverse: true, // Newest at bottom
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.senderId == widget.currentUserId;
                            return _buildMessageBubble(msg, isMe);
                          },
                        );
                      },
                    ),
                  ),

                  // Input Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: context.cardBorder)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.attach_file, color: context.mutedText),
                          onPressed: () {}, // Add attachment logic
                        ),
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            focusNode: _focusNode,
                            style: TextStyle(color: context.textColor),
                            decoration: InputDecoration(
                              hintText: tr('chat.type_message'),
                              hintStyle: TextStyle(color: context.mutedText),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // Staff Online Presence Sidebar (Optional)
          Container(
            width: 250,
            margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(context.cardRadius),
              border: Border.all(color: context.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(tr('chat.online_staff'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize, color: context.textColor)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildUserPresenceTile('Admin', true),
                      _buildUserPresenceTile('Sales Manager', true),
                      _buildUserPresenceTile('Store Keeper', false),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white10,
              child: Text(msg.senderName.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.orange : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                  bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                ),
                border: isMe ? null : Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(msg.senderName, style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                    ),
                  Text(msg.text, style: TextStyle(color: isMe ? Colors.black : Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp), 
                    style: TextStyle(fontSize: 10, color: isMe ? Colors.black54 : Colors.white38)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPresenceTile(String name, bool isOnline) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white10,
            child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(name, style: TextStyle(color: isOnline ? Colors.white : Colors.white54)),
    );
  }
}
