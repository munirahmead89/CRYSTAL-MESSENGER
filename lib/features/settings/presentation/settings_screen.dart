import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/hive_service.dart';
import '../../subscription/presentation/premium_dashboard.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      _profile = await SupabaseService.getCurrentProfile();
    } catch (e) {
      debugPrint('[SettingsScreen] Load profile error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SIGN OUT', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HiveService.instance.clearSession();
      await HiveService.instance.setProfileCompleted(false);
      await SupabaseService.auth.signOut();
      // GoRouter redirect fires automatically.
    }
  }

  Future<void> _clearCache() async {
    await HiveService.instance.messagesBox.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat cache cleared.'),
          backgroundColor: Color(0xFF25D366),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _profile?['full_name'] ?? _profile?['username'] ?? 'Crystal User';
    final String email       = SupabaseService.auth.currentUser?.email ?? '';
    final String? avatar     = _profile?['avatar_url'];
    final String status      = _profile?['status'] ?? 'Hey there!';
    final bool   isPremium   = _profile?['is_premium'] ?? false;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF075E54).withValues(alpha: 0.12),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AppBar ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                        onPressed: () => context.pop(),
                      ),
                      const Text(
                        'Settings',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            // ── Profile Card ──────────────────────────────────
                            GlassContainer(
                              blur: 10,
                              color: Colors.white.withValues(alpha: 0.04),
                              border: Border.all(color: Colors.white10),
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 34,
                                          backgroundColor: const Color(0xFF1a1a1a),
                                          backgroundImage: avatar != null
                                              ? CachedNetworkImageProvider(avatar)
                                              : null,
                                          child: avatar == null
                                              ? const Icon(Icons.person, color: Colors.white38, size: 34)
                                              : null,
                                        ),
                                        if (isPremium)
                                          Positioned(
                                            bottom: 0, right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Colors.amber,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.star, size: 12, color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            status,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF25D366)),
                                      onPressed: () => context.push('/profile-setup'),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Premium section ───────────────────────────────
                            _buildSectionHeader('Subscription'),
                            _buildTile(
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber,
                              title: 'Crystal Premium',
                              subtitle: isPremium ? 'Founder status active' : 'Unlock exclusive features',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PremiumDashboard()),
                              ),
                              trailing: isPremium
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : null,
                            ),

                            const SizedBox(height: 20),

                            // ── Privacy & Storage ─────────────────────────────
                            _buildSectionHeader('Privacy & Storage'),
                            _buildTile(
                              icon: Icons.delete_sweep_outlined,
                              iconColor: Colors.orangeAccent,
                              title: 'Clear Chat Cache',
                              subtitle: 'Removes offline message cache',
                              onTap: _clearCache,
                            ),
                            _buildTile(
                              icon: Icons.sync,
                              iconColor: const Color(0xFF25D366),
                              title: 'Sync Contacts',
                              subtitle: 'Find friends on Crystal',
                              onTap: () => context.push('/contact-sync'),
                            ),

                            const SizedBox(height: 20),

                            // ── Account ───────────────────────────────────────
                            _buildSectionHeader('Account'),
                            _buildTile(
                              icon: Icons.logout,
                              iconColor: Colors.redAccent,
                              title: 'Sign Out',
                              subtitle: 'Sign out of your account',
                              titleColor: Colors.redAccent,
                              onTap: _signOut,
                            ),

                            const SizedBox(height: 40),

                            // App version footer
                            Center(
                              child: Text(
                                'Crystal Messenger  v1.1.0\nBuilt by Munir Waheed',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white24, fontSize: 11, height: 1.7),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF25D366),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Widget? trailing,
  }) {
    return GlassContainer(
      blur: 8,
      color: Colors.white.withValues(alpha: 0.03),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor ?? Colors.white,
            fontSize: 15,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}
