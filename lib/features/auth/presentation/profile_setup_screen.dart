import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../../../core/services/admob_service.dart';
import '../../../core/services/supabase_service.dart';
import 'package:go_router/go_router.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _statusController =
      TextEditingController(text: 'Hey there! I am using Crystal Messenger.');
  final _phoneController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    final profile = await SupabaseService.getCurrentProfile();
    if (!mounted) return;
    if (profile != null) {
      _fullNameController.text = profile['full_name'] ?? '';
      _usernameController.text = profile['username'] ?? '';
      _statusController.text =
          profile['status'] ?? 'Hey there! I am using Crystal Messenger.';
      _phoneController.text = profile['phone'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Display name is required'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Username is required'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;
      if (_imageFile != null) {
        avatarUrl = await SupabaseService.uploadMedia(
          _imageFile!,
          'avatars/${SupabaseService.auth.currentUser?.id}',
        );
      }

      await SupabaseService.updateProfile(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim().toLowerCase(),
        status: _statusController.text.trim(),
        avatarUrl: avatarUrl,
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        AdMobService.instance.showInterstitialAd();
        context.go('/chat');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving profile: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _statusController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF075E54).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn().moveY(begin: -20, end: 0),
                    const SizedBox(height: 10),
                    const Text(
                      'Please provide your name, username, status, and an optional profile picture.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 35),

                    // Profile Picture Selector
                    GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF25D366), width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF25D366)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(65),
                              child: _imageFile != null
                                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                                  : Container(
                                      color: const Color(0xFF1a1a1a),
                                      child: const Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.white24,
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 40),

                    // Setup Form
                    GlassContainer(
                      blur: 15,
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(25),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Full Name
                            TextField(
                              controller: _fullNameController,
                              enabled: !_isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Display Name',
                                labelStyle:
                                    const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(Icons.badge_outlined,
                                    color: Color(0xFF25D366)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF25D366)),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Username
                            TextField(
                              controller: _usernameController,
                              enabled: !_isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle:
                                    const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(
                                    Icons.alternate_email_outlined,
                                    color: Color(0xFF25D366)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF25D366)),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Phone
                            TextField(
                              controller: _phoneController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Phone Number (For Sync)',
                                labelStyle:
                                    const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(Icons.phone_outlined,
                                    color: Color(0xFF25D366)),
                                hintText: '+1234567890',
                                hintStyle:
                                    const TextStyle(color: Colors.white24),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF25D366)),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Status text
                            TextField(
                              controller: _statusController,
                              enabled: !_isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Status',
                                labelStyle:
                                    const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(Icons.info_outline,
                                    color: Color(0xFF25D366)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF25D366)),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 35),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'COMPLETE SETUP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 450.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
