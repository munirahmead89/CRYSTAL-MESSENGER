import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'dart:async';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/models/models.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  StreamSubscription? _incomingCallSub;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startIncomingCallListener();
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Listens in background for incoming calling notifications via Supabase Realtime
  void _startIncomingCallListener() {
    _incomingCallSub = SupabaseService.streamIncomingCalls().listen((calls) {
      if (calls.isNotEmpty && mounted) {
        final call = CallSessionModel.fromJson(calls.first);
        _showRingingDialog(call);
      }
    });
  }

  void _showRingingDialog(CallSessionModel call) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isVideo = call.type == CallType.video;
        return PopScope(
          canPop: false, // Prevent dismissing by back button
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassContainer(
              blur: 20,
              color: Colors.black.withValues(alpha: 0.8),
              border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3), width: 1.5),
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVideo ? Icons.videocam : Icons.phone_in_talk,
                        color: const Color(0xFF25D366),
                        size: 40,
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 20),
                    const Text(
                      'CRYSTAL P2P CALL',
                      style: TextStyle(
                        color: Color(0xFF25D366),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVideo ? 'Incoming Video Call...' : 'Incoming Audio Call...',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Caller ID: ${call.callerId.substring(0, 8)}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Decline Button (Red)
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await SupabaseService.updateCallStatus(call.id, CallStatus.rejected);
                          },
                          icon: const Icon(Icons.call_end, color: Colors.white),
                          label: const Text('DECLINE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        // Accept Button (Green)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/call', extra: {
                              'sessionId': call.id,
                              'receiverId': call.receiverId,
                              'callType': call.type,
                              'isCaller': false,
                            });
                          },
                          icon: const Icon(Icons.call, color: Colors.white),
                          label: const Text('ACCEPT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF075E54), Color(0xFF25D366)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Crystal Messenger',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts, color: Colors.white70),
            onPressed: () => context.push('/contact-sync'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. WhatsApp Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: GlassContainer(
              blur: 10,
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white30, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Search chats...',
                          hintStyle: TextStyle(color: Colors.white30, fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.clear, color: Colors.white54, size: 16),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Chat list area
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: SupabaseService.getRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)));
                }

                final rawRooms = snapshot.data ?? [];
                var rooms = rawRooms.map((r) => RoomModel.fromJson(r)).toList();

                if (_searchQuery.isNotEmpty) {
                  rooms = rooms.where((r) => (r.name ?? 'Chat Room').toLowerCase().contains(_searchQuery)).toList();
                }

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 50, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No conversations found' : 'No chats yet',
                          style: const TextStyle(color: Colors.white30, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'Try refining your search keyword.' 
                              : 'Tap the contact icon or button below to sync contacts and chat!',
                          style: const TextStyle(color: Colors.white24, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: rooms.length,
                  separatorBuilder: (c, idx) => const Divider(color: Colors.white10, height: 1, indent: 80),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF1a1a1a),
                        backgroundImage: room.avatarUrl != null
                            ? NetworkImage(room.avatarUrl!)
                            : null,
                        child: room.avatarUrl == null
                            ? const Icon(Icons.person, color: Colors.white38, size: 28)
                            : null,
                      ),
                      title: Text(
                        room.name ?? 'Direct Chat (${room.id.substring(0, 6)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      subtitle: Text(
                        room.lastMessage ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 13),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${room.updatedAt.hour}:${room.updatedAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          const Icon(Icons.done_all, color: Color(0xFF25D366), size: 16), // Mock read status indicator
                        ],
                      ),
                      onTap: () => context.push('/chat/${room.id}'),
                    ).animate().fadeIn(delay: (index * 40).ms);
                  },
                );
              },
            ),
          ),

          // 3. AdMob Banner Ad (Production ready)
          AdMobService.instance.getBannerAdWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/contact-sync'),
        backgroundColor: const Color(0xFF25D366),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}
