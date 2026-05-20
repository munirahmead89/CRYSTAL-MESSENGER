import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

class MessageInputBar extends StatefulWidget {
  final String chatId;
  const MessageInputBar({Key? key, required this.chatId}) : super(key: key);

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final _textCtl = TextEditingController();
  bool _isRecording = false;
  final _recorder = Record();
  final _player = AudioPlayer();

  Future<void> _sendText() async {
    if (_textCtl.text.trim().isEmpty) return;
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': user.id,
        'content': _textCtl.text.trim(),
        'message_type': 'text',
      });
      _textCtl.clear();
    } catch (e) {
      AppLogger.e('SendText', e.toString());
    }
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result == null) return;
    final bytes = await result.readAsBytes();
    final fileName = 'media/${Supabase.instance.client.auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await Supabase.instance.client.storage.from('media').uploadBinary(fileName, bytes);
      final publicUrl = Supabase.instance.client.storage.from('media').getPublicUrl(fileName);
      await Supabase.instance.client.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': Supabase.instance.client.auth.currentUser!.id,
        'content': '',
        'message_type': 'image',
        'media_url': publicUrl.data,
      });
    } catch (e) {
      AppLogger.e('MediaUpload', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
    }
  }

  Future<void> _toggleRecord() async {
    if (!_isRecording) {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required')));
        return;
      }
      final path = '/tmp/record_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(path: path, encoder: AudioEncoder.aacLc);
      setState(() => _isRecording = true);
    } else {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final file = File(path);
        final bytes = await file.readAsBytes();
        final fileName = 'voice/${Supabase.instance.client.auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        try {
          await Supabase.instance.client.storage.from('media').uploadBinary(fileName, bytes);
          final publicUrl = Supabase.instance.client.storage.from('media').getPublicUrl(fileName);
          await Supabase.instance.client.from('messages').insert({
            'chat_id': widget.chatId,
            'sender_id': Supabase.instance.client.auth.currentUser!.id,
            'content': '',
            'message_type': 'audio',
            'media_url': publicUrl.data,
          });
        } catch (e) {
          AppLogger.e('VoiceUpload', e.toString());
        }
      }
    }
  }

  @override
  void dispose() {
    _textCtl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add), onPressed: _pickMedia),
            Expanded(
              child: TextField(
                controller: _textCtl,
                decoration: const InputDecoration.collapsed(hintText: 'Message'),
                onChanged: (text) {
                  // TODO: update typing indicator in DB (typing_indicators)
                },
              ),
            ),
            IconButton(icon: Icon(_isRecording ? Icons.stop : Icons.mic), onPressed: _toggleRecord),
            IconButton(icon: const Icon(Icons.send), onPressed: _sendText),
          ],
        ),
      ),
    );
  }
}
