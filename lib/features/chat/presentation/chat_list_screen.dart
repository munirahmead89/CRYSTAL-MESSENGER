import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/models.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crystal Messenger', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final rooms = (snapshot.data ?? []).map((r) => RoomModel.fromJson(r)).toList();
          
          if (rooms.isEmpty) {
            return const Center(child: Text('No conversations yet. Start messaging!'));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF075E54),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(room.name ?? 'Chat Room ${room.id.substring(0, 5)}'),
                subtitle: Text(room.lastMessage ?? 'No messages yet'),
                onTap: () => context.push('/chat/${room.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
