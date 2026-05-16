import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/models.dart';

class ChatDetailScreen extends StatefulWidget {
  final String roomId;
  const ChatDetailScreen({super.key, required this.roomId});
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();

  void _send() async {
    if (_controller.text.isEmpty) return;
    try {
      await SupabaseService.sendMessage(roomId: widget.roomId, content: _controller.text);
      _controller.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: GlassContainer(
          blur: 15,
          color: Colors.white.withValues(alpha: 0.02),
          border: const Border(bottom: BorderSide(color: Colors.white10)),
          child: AppBar(
            title: const Text('Crystal Chat', style: TextStyle(fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
              IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF25D366).withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseService.getMessagesStream(widget.roomId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final messages = (snapshot.data ?? []).map((m) => MessageModel.fromJson(m)).toList();
                    
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final m = messages[messages.length - 1 - index];
                        final isMe = m.senderId == SupabaseService.auth.currentUser?.id;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: GlassContainer(
                              blur: 5,
                              color: isMe 
                                  ? const Color(0xFF075E54).withValues(alpha: 0.4) 
                                  : Colors.white.withValues(alpha: 0.05),
                              border: Border.all(color: Colors.white10),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(m.textContent ?? '', style: const TextStyle(fontSize: 16, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${m.createdAt.hour}:${m.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 10, color: Colors.white60),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: GlassContainer(
                  blur: 15,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.grey),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type a crystal message...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _send,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
