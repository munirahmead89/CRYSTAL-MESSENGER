import 'package:flutter/material.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (_, i) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text('Contact $i'),
        subtitle: const Text('Last message preview...'),
        trailing: const Text('2:12 PM'),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatRoomPage(chatId: 'placeholder-chat-id')));
        },
      ),
    );
  }
}
