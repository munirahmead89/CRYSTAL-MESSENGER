import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import 'message_input_bar.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  const ChatRoomPage({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _messages = <Map<String, dynamic>>[];
  RealtimeChannel? _subMessages;
  RealtimeChannel? _subTyping;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final res = await Supabase.instance.client.from('messages').select('*').eq('chat_id', widget.chatId).order('created_at', const FetchOrder.desc).limit(50);
      if (res != null && res is List) {
        setState(() {
          _messages.addAll(List<Map<String, dynamic>>.from(res));
        });
      }

      _subMessages = Supabase.instance.client.channel('public:messages');
      _subMessages!.on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'INSERT', schema: 'public', table: 'messages', filter: 'chat_id=eq.${widget.chatId}'), (payload, [ref]) {
        if (payload is RealtimePostgresChangesPayload) {
          setState(() {
            _messages.insert(0, Map<String, dynamic>.from(payload.newRecord ?? {}));
          });
        }
      });
      Supabase.instance.client.addChannel(_subMessages!);
      _subMessages!.subscribe();

      _subTyping = Supabase.instance.client.channel('public:typing_indicators');
      _subTyping!.on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: '*', schema: 'public', table: 'typing_indicators', filter: 'chat_id=eq.${widget.chatId}'), (payload, [ref]) {
        // parse typing indicators and show UI
      });
      Supabase.instance.client.addChannel(_subTyping!);
      _subTyping!.subscribe();
    } catch (e) {
      AppLogger.e('ChatInit', e.toString());
    }
  }

  @override
  void dispose() {
    _subMessages?.unsubscribe();
    _subTyping?.unsubscribe();
    super.dispose();
  }

  Widget _buildMessage(Map<String, dynamic> m) {
    final isMe = m['sender_id'] == Supabase.instance.client.auth.currentUser?.id;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(m['content'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.videocam)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessage(_messages[i]),
            ),
          ),
          const Divider(height: 1),
          MessageInputBar(chatId: widget.chatId),
        ],
      ),
    );
  }
}
