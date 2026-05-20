import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../dashboard/dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _displayNameCtl = TextEditingController();
  final _statusCtl = TextEditingController();
  String? _avatarUrl;
  bool _loading = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result == null) return;
    setState(() => _loading = true);
    final bytes = await result.readAsBytes();
    final fileName = 'avatars/${Supabase.instance.client.auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await Supabase.instance.client.storage.from('avatars').uploadBinary(fileName, bytes);
      final public = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
      setState(() {
        _avatarUrl = public.data;
      });
    } catch (e) {
      AppLogger.e('AvatarUpload', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar upload failed')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final profile = {
        'auth_id': user.id,
        'email': user.email,
        'display_name': _displayNameCtl.text.trim(),
        'avatar_url': _avatarUrl,
        'status_text': _statusCtl.text.trim(),
      };
      await Supabase.instance.client.from('profiles').upsert(profile, returning: ReturningOption.minimal);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardPage()));
    } catch (e) {
      AppLogger.e('SaveProfile', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _displayNameCtl.dispose();
    _statusCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: CircleAvatar(
              radius: 48,
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null ? const Icon(Icons.add_a_photo, size: 36) : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _displayNameCtl, decoration: const InputDecoration(labelText: 'Display name')),
          const SizedBox(height: 8),
          TextField(controller: _statusCtl, decoration: const InputDecoration(labelText: 'Status')),
          const Spacer(),
          ElevatedButton(
            onPressed: _loading ? null : _saveProfile,
            child: _loading ? const CircularProgressIndicator() : const Text('Continue to Crystal'),
          )
        ]),
      ),
    );
  }
}
