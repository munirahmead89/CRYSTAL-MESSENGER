import '../../data/models/auth_user_model.dart';

/// Abstract repository for authentication
abstract class AuthRepository {
  Future<AuthUserModel> signInWithGoogle();
  Future<void> signOut();
  Future<AuthUserModel?> getCurrentUser();
  Future<void> createUserProfile({
    required String userId,
    required String displayName,
    required String email,
    String? profilePictureUrl,
    String? status,
  });
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? profilePictureUrl,
    String? status,
  });
  Future<Map<String, dynamic>> getUserProfile(String userId);
  Future<bool> profileExists(String userId);
  Future<void> updateOnlineStatus(String userId, bool isOnline);
}
