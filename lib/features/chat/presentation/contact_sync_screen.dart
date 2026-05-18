import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/contact_service.dart';
import '../../../core/models/models.dart';

class ContactSyncScreen extends StatefulWidget {
  const ContactSyncScreen({super.key});

  @override
  State<ContactSyncScreen> createState() => _ContactSyncScreenState();
}

class _ContactSyncScreenState extends State<ContactSyncScreen> {
  List<UserModel> _matchedUsers = [];
  bool _isLoading = false;
  String _statusMessage = 'Access contacts to sync your friends.';
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndSync();
  }

  Future<void> _checkPermissionAndSync() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting permissions...';
    });

    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        await _performSync();
      } else {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
          _statusMessage =
              'Permission denied. Please grant contact permissions in Settings.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error requesting permissions: $e';
      });
    }
  }

  Future<void> _performSync() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Reading local contacts...';
    });

    try {
      final matched = await ContactService.instance.syncAppContacts();

      // Remove self from the list
      final selfId = SupabaseService.auth.currentUser?.id;
      final filteredMatched = matched.where((u) => u.id != selfId).toList();

      setState(() {
        _matchedUsers = filteredMatched;
        _isLoading = false;
        _statusMessage = filteredMatched.isEmpty
            ? 'None of your contacts are currently on Crystal Messenger.'
            : 'Successfully synced contacts!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sync failed: $e';
      });
    }
  }

  void _startChat(UserModel contact) async {
    setState(() => _isLoading = true);
    try {
      final room = await SupabaseService.getOrCreateDirectRoom(contact.id);
      if (mounted) {
        context.pushReplacement('/chat/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to open chat: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _performSync,
          )
        ],
      ),
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF075E54).withValues(alpha: 0.1),
              ),
            ),
          ),

          Column(
            children: [
              // Sync status banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF1a1a1a),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF25D366)),
                      )
                    else
                      const Icon(Icons.sync,
                          color: Color(0xFF25D366), size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70),
                      ),
                    ),
                    if (_permissionDenied)
                      TextButton(
                        onPressed: () => openAppSettings(),
                        child: const Text('SETTINGS',
                            style: TextStyle(
                                color: Color(0xFF25D366), fontSize: 12)),
                      )
                  ],
                ),
              ),

              Expanded(
                child: _matchedUsers.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.contacts_outlined,
                                size: 60, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text(
                              'No Contacts Synced Yet',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white60),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _permissionDenied
                                    ? 'Contact permission is required to find friends automatically.'
                                    : 'Invite friends to download Crystal Messenger and start secure calling!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white30),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _matchedUsers.length,
                        separatorBuilder: (c, idx) => const Divider(
                            color: Colors.white10, height: 1, indent: 80),
                        itemBuilder: (context, index) {
                          final user = _matchedUsers[index];
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: user.isPremium
                                      ? Colors.amber
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: const Color(0xFF1a1a1a),
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? const Icon(Icons.person,
                                        color: Colors.white38)
                                    : null,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                if (user.isPremium)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.amber.withValues(alpha: 0.1),
                                      border: Border.all(
                                          color: Colors.amber, width: 0.5),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'FOUNDER',
                                      style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              user.status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0x80FFFFFF), fontSize: 13),
                            ),
                            onTap: () => _startChat(user),
                          ).animate().fadeIn(delay: (index * 50).ms);
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
