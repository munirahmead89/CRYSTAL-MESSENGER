import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'dart:async';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/models/models.dart';

class ChatDetailScreen extends StatefulWidget {
  final String roomId;
  const ChatDetailScreen({super.key, required this.roomId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Audio Recording (Voice Notes)
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  String _recordingDurationText = '0:00';

  // Typing state debouncing
  bool _isTyping = false;
  Timer? _typingDebounce;

  // Participant details
  String? _otherUserId;
  String _otherUserName = 'Crystal User';
  String? _otherUserAvatar;
  bool _otherUserOnline = false;
  bool _otherUserTyping = false;
  StreamSubscription? _typingSub;

  // Offline Caching
  List<MessageModel> _cachedMessages = [];

  @override
  void initState() {
    super.initState();
    _loadCachedHistory();
    _fetchRoomParticipants();
    _listenToTypingIndicators();
    _markChatAsRead();

    // Show non-intrusive Interstitial Ad when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdMobService.instance.showInterstitialAd();
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _typingSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Caching: Pre-load instantly from Hive local cache
  void _loadCachedHistory() {
    final cached = HiveService.instance.getCachedMessages(widget.roomId);
    setState(() {
      _cachedMessages = cached.map((e) => MessageModel.fromJson(e)).toList();
    });
  }

  // Get recipient participant id for call signaling and profile display
  Future<void> _fetchRoomParticipants() async {
    try {
      final myId = SupabaseService.auth.currentUser?.id;
      final response = await SupabaseService.client
          .from('participants')
          .select('user_id')
          .eq('room_id', widget.roomId);

      final other = (response as List).firstWhere(
        (p) => p['user_id'] != myId,
        orElse: () => null,
      );

      if (other != null) {
        _otherUserId = other['user_id'];
        _fetchOtherUserProfile();
      }
    } catch (e) {
      debugPrint('[ChatDetailScreen] Fetch participants error: $e');
    }
  }

  Future<void> _fetchOtherUserProfile() async {
    if (_otherUserId == null) return;
    try {
      final profile = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', _otherUserId!)
          .single();

      if (mounted) {
        setState(() {
          _otherUserName =
              profile['full_name'] ?? profile['username'] ?? 'Crystal User';
          _otherUserAvatar = profile['avatar_url'];
          _otherUserOnline = profile['is_online'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('[ChatDetailScreen] Fetch other profile error: $e');
    }
  }

  // Typing indicators: Stream updates
  void _listenToTypingIndicators() {
    _typingSub =
        SupabaseService.getTypingStream(widget.roomId).listen((indicators) {
      if (!mounted || _otherUserId == null) return;

      final matches = indicators.where((t) => t['user_id'] == _otherUserId);
      if (matches.isEmpty) {
        setState(() {
          _otherUserTyping = false;
        });
        return;
      }
      final otherTypingState = matches.first;

      final bool isTypingNow = otherTypingState['is_typing'] ?? false;
      final DateTime updatedAt = DateTime.parse(otherTypingState['updated_at']);

      // Typing indicator expires if not updated in 6 seconds
      final bool isExpired = DateTime.now().difference(updatedAt).inSeconds > 6;

      setState(() {
        _otherUserTyping = isTypingNow && !isExpired;
      });
    });
  }

  // Mark all incoming messages in this chat as read
  Future<void> _markChatAsRead() async {
    await SupabaseService.markRoomMessagesAsRead(widget.roomId);
  }

  // Handle keypresses for real-time typing indicators
  void _onTextChanged(String val) {
    if (_typingDebounce?.isActive ?? false) _typingDebounce!.cancel();

    if (!_isTyping && val.trim().isNotEmpty) {
      _isTyping = true;
      SupabaseService.setTypingStatus(widget.roomId, true);
    }

    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        SupabaseService.setTypingStatus(widget.roomId, false);
      }
    });
  }

  // Attachment Menu Sheet
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainer(
          blur: 20,
          color: Colors.black.withValues(alpha: 0.85),
          border: const Border(top: BorderSide(color: Colors.white10)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Share Secure Content',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAttachmentBtn(
                        icon: Icons.image,
                        color: Colors.purpleAccent,
                        label: 'Gallery',
                        onTap: () {
                          Navigator.pop(context);
                          _pickMedia(ImageSource.gallery);
                        },
                      ),
                      _buildAttachmentBtn(
                        icon: Icons.camera_alt,
                        color: Colors.redAccent,
                        label: 'Camera',
                        onTap: () {
                          Navigator.pop(context);
                          _pickMedia(ImageSource.camera);
                        },
                      ),
                      _buildAttachmentBtn(
                        icon: Icons.description,
                        color: Colors.blueAccent,
                        label: 'Document',
                        onTap: () {
                          Navigator.pop(context);
                          _pickDocument();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border:
                  Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  // Media Picker Logic
  Future<void> _pickMedia(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;

      final file = File(picked.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 15),
          Text('Uploading photo...')
        ])),
      );

      final url =
          await SupabaseService.uploadMedia(file, 'photos/${widget.roomId}');
      if (!mounted) return;
      if (url != null) {
        await SupabaseService.sendMessage(
          roomId: widget.roomId,
          mediaUrl: url,
          type: MessageType.image,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  // Document Picker Logic
  Future<void> _pickDocument() async {
    try {
      // ignore: undefined_getter
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 15),
          Text('Uploading document...')
        ])),
      );

      final url = await SupabaseService.uploadMedia(
          file, 'documents/${widget.roomId}',
          bucket: 'media');
      if (!mounted) return;
      if (url != null) {
        await SupabaseService.sendMessage(
          roomId: widget.roomId,
          content: result.files.single.name,
          mediaUrl: url,
          type: MessageType.document,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Document upload failed: $e')));
    }
  }

  // Voice Notes: Recording start
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        _recordingStartTime = DateTime.now();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_recordingStartTime != null) {
            final diff = DateTime.now().difference(_recordingStartTime!);
            final minutes = diff.inMinutes;
            final seconds = diff.inSeconds % 60;
            setState(() {
              _recordingDurationText =
                  '$minutes:${seconds.toString().padLeft(2, '0')}';
            });
          }
        });

        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _recordingDurationText = '0:00';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Microphone error: $e')));
    }
  }

  // Voice Notes: Recording stop and send
  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null && _recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Row(children: [
              CircularProgressIndicator(),
              SizedBox(width: 15),
              Text('Sending voice note...')
            ])),
          );

          final url = await SupabaseService.uploadMedia(
              file, 'audio/${widget.roomId}',
              bucket: 'media');
          if (url != null) {
            await SupabaseService.sendMessage(
              roomId: widget.roomId,
              mediaUrl: url,
              type: MessageType.audio,
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to record: $e')));
    }
  }

  // Voice Notes: Cancel recording
  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordingPath = null;
    });
  }

  // WebRTC Calling triggering
  void _initiateCall(CallType type) {
    if (_otherUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Call dialing unavailable: Recipient profile syncing...'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    context.push('/call', extra: {
      'sessionId': null,
      'receiverId': _otherUserId,
      'callType': type,
      'isCaller': true,
    });
  }

  void _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text;
    _messageController.clear();

    // Stop typing indicators immediately
    _typingDebounce?.cancel();
    _isTyping = false;
    SupabaseService.setTypingStatus(widget.roomId, false);

    try {
      await SupabaseService.sendMessage(roomId: widget.roomId, content: text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Send failed: $e')));
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
          color: Colors.black.withValues(alpha: 0.6),
          border: const Border(bottom: BorderSide(color: Colors.white10)),
          child: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
              onPressed: () => context.pop(),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1a1a1a),
                  backgroundImage: _otherUserAvatar != null
                      ? NetworkImage(_otherUserAvatar!)
                      : null,
                  child: _otherUserAvatar == null
                      ? const Icon(Icons.person,
                          color: Colors.white54, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _otherUserName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _otherUserTyping
                            ? 'typing...'
                            : (_otherUserOnline ? 'online' : 'offline'),
                        style: TextStyle(
                          fontSize: 11,
                          color: _otherUserTyping
                              ? const Color(0xFF25D366)
                              : Colors.white30,
                          fontWeight: _otherUserTyping
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.videocam_outlined, color: Colors.white70),
                onPressed: () => _initiateCall(CallType.video),
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined, color: Colors.white70),
                onPressed: () => _initiateCall(CallType.audio),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // WhatsApp dark green abstract background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF070c0e),
            ),
          ),

          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseService.getMessagesStream(widget.roomId),
                  builder: (context, snapshot) {
                    // Update cache when new stream database packages arrive
                    if (snapshot.hasData) {
                      final newMessages = snapshot.data!
                          .map((m) => MessageModel.fromJson(m))
                          .toList();

                      // Cache asynchronous arrivals locally in Hive
                      for (final msg in newMessages) {
                        HiveService.instance
                            .cacheMessage(widget.roomId, msg.toJson());
                      }

                      _cachedMessages = newMessages;
                    }

                    if (_cachedMessages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(color: Colors.white30),
                        ),
                      );
                    }

                    // Render sorted messages
                    final displayList =
                        List<MessageModel>.from(_cachedMessages);

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 110, 16, 20),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final msg = displayList[displayList.length - 1 - index];
                        final bool isMe = msg.senderId ==
                            SupabaseService.auth.currentUser?.id;

                        return _buildMessageBubble(msg, isMe);
                      },
                    );
                  },
                ),
              ),

              // Dynamic On-the-fly typing indicator overlay
              if (_otherUserTyping)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 16, 8),
                    child: Text(
                      '$_otherUserName is typing...',
                      style: const TextStyle(
                          color: Color(0xFF25D366),
                          fontSize: 11,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ),

              // Chat Input Bar (Muted Glassmorphic bar)
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  // Interactive Message Bubbles
  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: GlassContainer(
            blur: 5,
            color: isMe
                ? const Color(0xFF075E54).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isMe
                  ? const Color(0xFF075E54).withValues(alpha: 0.3)
                  : Colors.white10,
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBubbleContent(msg),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Spacer(),
                      Text(
                        '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                        style:
                            const TextStyle(fontSize: 9, color: Colors.white30),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color:
                              msg.isRead ? Colors.blueAccent : Colors.white30,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildBubbleContent(MessageModel msg) {
    switch (msg.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            msg.mediaUrl!,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                width: 150,
                height: 150,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF25D366))),
              );
            },
          ),
        );
      case MessageType.document:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.amber, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg.textContent ?? 'Document',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    decoration: TextDecoration.underline),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MessageType.audio:
        return VoiceNoteBubble(url: msg.mediaUrl!);
      case MessageType.text:
      default:
        return Text(
          msg.textContent ?? '',
          style: const TextStyle(fontSize: 15, color: Colors.white),
        );
    }
  }

  // Pixel-Perfect Input Bar
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 28),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              blur: 15,
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Attachment button
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white70),
                      onPressed: _isRecording ? null : _showAttachmentMenu,
                    ),
                    Expanded(
                      child: _isRecording
                          ? Row(
                              children: [
                                const Icon(Icons.fiber_manual_record,
                                        color: Colors.redAccent, size: 16)
                                    .animate(
                                        onPlay: (controller) =>
                                            controller.repeat())
                                    .fadeOut(duration: 800.ms),
                                const SizedBox(width: 8),
                                Text(
                                  'Recording Voice Note: $_recordingDurationText',
                                  style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white54),
                                  onPressed: _cancelRecording,
                                ),
                              ],
                            )
                          : TextField(
                              controller: _messageController,
                              onChanged: _onTextChanged,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Message...',
                                hintStyle: TextStyle(
                                    color: Colors.white30, fontSize: 15),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                    ),
                    if (!_isRecording)
                      IconButton(
                        icon:
                            const Icon(Icons.camera_alt, color: Colors.white70),
                        onPressed: () => _pickMedia(ImageSource.camera),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send / Mic Circle Floating Button
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopAndSendRecording(),
            onTap: _isRecording ? _stopAndSendRecording : _sendTextMessage,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording
                    ? Icons.send
                    : (_messageController.text.trim().isEmpty
                        ? Icons.mic
                        : Icons.send),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Complete Voice Note audio player bubble
class VoiceNoteBubble extends StatefulWidget {
  final String url;
  const VoiceNoteBubble({super.key, required this.url});

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(widget.url));
      }
    } catch (e) {
      debugPrint('[VoiceNoteBubble] Playback error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
              color: const Color(0xFF25D366), size: 28),
          onPressed: _togglePlay,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2.0,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14.0),
                  activeTrackColor: const Color(0xFF25D366),
                  inactiveTrackColor: Colors.white24,
                  thumbColor: const Color(0xFF25D366),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (val) async {
                    final newPos = Duration(
                        milliseconds: (val * _duration.inMilliseconds).toInt());
                    await _audioPlayer.seek(newPos);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
                    style:
                        const TextStyle(fontSize: 10, color: Color(0x80FFFFFF)),
                  ),
                  Text(
                    '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style:
                        const TextStyle(fontSize: 10, color: Color(0x80FFFFFF)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
