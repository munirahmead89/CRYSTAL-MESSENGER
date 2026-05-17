import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/supabase_service.dart';

/// Auth Screen — supports both Google OAuth (primary) and email+password fallback.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isSignUp   = false;
  bool _isLoading  = false;
  bool _showEmailForm = false;   // Toggle email/password section

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.signInWithGoogle();
      // On mobile the OAuth redirect triggers a deep link back to the app;
      // on web the page redirects. The GoRouter redirect() handles navigation
      // once the Supabase auth-state listener fires.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Email / Password Auth ───────────────────────────────────────────────────
  Future<void> _emailAuth() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await SupabaseService.auth.signUp(email: email, password: pass);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Check your email to confirm.'),
              backgroundColor: Color(0xFF25D366),
            ),
          );
        }
      } else {
        await SupabaseService.auth.signInWithPassword(email: email, password: pass);
        // Router redirect handles /profile-setup or /chat navigation automatically.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06080a), Color(0xFF0d1117), Color(0xFF06080a)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Ambient glow top-right
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF075E54).withValues(alpha: 0.18),
              ),
            ),
          ),
          // Ambient glow bottom-left
          Positioned(
            bottom: -60, left: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF25D366).withValues(alpha: 0.08),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF075E54), Color(0xFF25D366)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF25D366).withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.diamond_outlined, size: 48, color: Colors.white),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 28),

                    Text(
                      'Crystal Messenger',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                    ).animate().fadeIn(delay: 150.ms).moveY(begin: 15, end: 0),

                    const SizedBox(height: 6),

                    Text(
                      _showEmailForm
                          ? (_isSignUp ? 'Create your account' : 'Sign in to continue')
                          : 'Sign in securely with Google',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 40),

                    // ── Google Sign-In Button ──────────────────────────────────
                    GlassContainer(
                      blur: 16,
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : const Icon(Icons.g_mobiledata, size: 32, color: Colors.white),
                                label: Text(
                                  _isLoading ? 'Connecting...' : 'Continue with Google',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4285F4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider(color: Colors.white12)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'or use email',
                                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                                  ),
                                ),
                                const Expanded(child: Divider(color: Colors.white12)),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Toggle email form visibility
                            TextButton(
                              onPressed: () => setState(() => _showEmailForm = !_showEmailForm),
                              child: Text(
                                _showEmailForm ? 'Hide email form' : 'Sign in with Email / Password',
                                style: const TextStyle(color: Color(0xFF25D366), fontSize: 13),
                              ),
                            ),

                            // ── Email + Password Form (collapsible) ────────────
                            if (_showEmailForm) ...[
                              const SizedBox(height: 4),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: const TextStyle(color: Colors.white60),
                                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF25D366)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.white12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFF25D366)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passCtrl,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(color: Colors.white60),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF25D366)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.white12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFF25D366)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _emailAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account? Sign In'
                                      : 'New to Crystal? Create Account',
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms).moveY(begin: 20, end: 0),

                    const SizedBox(height: 32),

                    // Terms note
                    Text(
                      'By continuing you agree to Crystal Messenger\'s\nTerms of Service & Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white24, fontSize: 11),
                    ).animate().fadeIn(delay: 500.ms),
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
