// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  });
  Future<void> logout();
  Future<UserModel?> checkSession();
  Future<UserModel> getCurrentUser();
  Future<void> acceptPrivacyPolicy(String userId);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> sendPasswordResetEmail(String email);
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final sb.SupabaseClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthFailure(message: 'Đăng nhập thất bại.');
      }

      return _fetchUserProfile(response.user!.id);
    } on sb.AuthException catch (e) {
      _throwAuthFailure(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role.code,
        },
      );

      if (response.user == null) {
        throw const AuthFailure(message: 'Đăng ký thất bại.');
      }

      // Việc insert vào bảng users được thực hiện tự động qua Trigger handle_new_user trong Supabase.

      return _fetchUserProfile(response.user!.id);
    } on sb.AuthException catch (e) {
      _throwAuthFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserModel?> checkSession() async {
    final session = _client.auth.currentSession;
    if (session == null || _client.auth.currentUser == null) {
      return null;
    }
    return _fetchUserProfile(_client.auth.currentUser!.id);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const SessionExpiredFailure();
    }
    return _fetchUserProfile(user.id);
  }

  @override
  Future<void> acceptPrivacyPolicy(String userId) async {
    await _client
        .from(AppConstants.tableUsers)
        .update({
          'has_accepted_privacy_policy': true,
          'ngaycapnhat': DateTime.now().toIso8601String(),
        })
        .eq('iduser', userId);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );
    } on sb.AuthException catch (e) {
      _throwAuthFailure(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on sb.AuthException catch (e) {
      _throwAuthFailure(e);
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session?.user == null) return null;
      try {
        return await _fetchUserProfile(event.session!.user.id);
      } catch (_) {
        return null;
      }
    });
  }

  // ── Private Helpers ──────────────────────────────────────────────────────

  Future<UserModel> _fetchUserProfile(String userId) async {
    final data = await _client
        .from(AppConstants.tableUsers)
        .select()
        .eq('iduser', userId)
        .single();

    return UserModel.fromJson(data);
  }

  Never _throwAuthFailure(sb.AuthException e) {
    switch (e.statusCode) {
      case '400':
        throw const InvalidCredentialsFailure();
      case '422':
        throw ValidationFailure(message: e.message);
      default:
        throw AuthFailure(message: e.message);
    }
  }
}
