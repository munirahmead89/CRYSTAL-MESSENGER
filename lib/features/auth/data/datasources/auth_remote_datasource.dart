import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_user_model.dart';

/// Remote data source for authentication operations via Supabase
class AuthRemoteDataSource {
  final SupabaseClient supabase;

  AuthRemoteDataSource(this.supabase);

  /// Sign in with Google via Supabase Auth
  /// Returns authenticated user
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      final AuthResponse response = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectUrl: 'io.supabase.crystal-messenger://login-callback',
      );

      if (response.user == null) throw Exception('Google sign-in failed');

      final user = response.user!;
      return AuthUserModel.fromSupabaseUser(user);
    } catch (e) {
      throw Exception('Google OAuth error: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out error: $e');
    }
  }

  /// Get current authenticated user
  Future<AuthUserModel?> getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      return user != null ? AuthUserModel.fromSupabaseUser(user) : null;
    } catch (e) {
      throw Exception('Get current user error: $e');
    }
  }

  /// Create user profile after first login
  Future<void> createUserProfile({
    required String userId,
    required String displayName,
    required String email,
    String? profilePictureUrl,
    String? status,
  }) async {
    try {
      await supabase.from('auth_profiles').insert({
        'user_id': userId,
        'display_name': displayName,
        'email': email,
        'profile_picture_url': profilePictureUrl,
        'status': status ?? 'Hey there! I am using Crystal Messenger.',
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Create profile error: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? profilePictureUrl,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['display_name'] = displayName;
      if (profilePictureUrl != null) updateData['profile_picture_url'] = profilePictureUrl;
      if (status != null) updateData['status'] = status;

      if (updateData.isNotEmpty) {
        await supabase.from('auth_profiles').update(updateData).eq('user_id', userId);
      }
    } catch (e) {
      throw Exception('Update profile error: $e');
    }
  }

  /// Get user profile by ID
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('auth_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Get profile error: $e');
    }
  }

  /// Check if profile exists
  Future<bool> profileExists(String userId) async {
    try {
      final response = await supabase
          .from('auth_profiles')
          .select('user_id')
          .eq('user_id', userId);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Update user online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await supabase.from('auth_profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e) {
      // Silent fail - not critical
    }
  }
}
