import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_user_model.dart';
import '../../../../core/exceptions/app_exceptions.dart';

/// Implementation of AuthRepository using Supabase
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      return await remoteDataSource.signInWithGoogle();
    } on Exception catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } on Exception catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  @override
  Future<AuthUserModel?> getCurrentUser() async {
    try {
      return await remoteDataSource.getCurrentUser();
    } on Exception catch (e) {
      throw AuthException('Get current user failed: $e');
    }
  }

  @override
  Future<void> createUserProfile({
    required String userId,
    required String displayName,
    required String email,
    String? profilePictureUrl,
    String? status,
  }) async {
    try {
      await remoteDataSource.createUserProfile(
        userId: userId,
        displayName: displayName,
        email: email,
        profilePictureUrl: profilePictureUrl,
        status: status,
      );
    } on Exception catch (e) {
      throw AuthException('Create profile failed: $e');
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? profilePictureUrl,
    String? status,
  }) async {
    try {
      await remoteDataSource.updateUserProfile(
        userId: userId,
        displayName: displayName,
        profilePictureUrl: profilePictureUrl,
        status: status,
      );
    } on Exception catch (e) {
      throw AuthException('Update profile failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      return await remoteDataSource.getUserProfile(userId);
    } on Exception catch (e) {
      throw AuthException('Get profile failed: $e');
    }
  }

  @override
  Future<bool> profileExists(String userId) async {
    try {
      return await remoteDataSource.profileExists(userId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await remoteDataSource.updateOnlineStatus(userId, isOnline);
    } catch (e) {
      // Silent fail
    }
  }
}
