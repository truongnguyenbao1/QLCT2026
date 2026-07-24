import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/security/encryption_service.dart';

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
    String? cccd,
    String? plan,
  });
  Future<void> logout();
  Future<UserModel?> checkSession();
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
  });
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
  final FlutterSecureStorage _storage;
  final EncryptionService _encryptionService;

  AuthRemoteDataSourceImpl(this._client, this._storage, this._encryptionService);

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

      await _storage.write(key: 'last_login_time', value: DateTime.now().toIso8601String());

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
    String? cccd,
    String? plan,
  }) async {
    try {
      Map<String, dynamic>? tenantData;

      // 1. Kiểm tra CCCD nếu là Khách thuê
      if (role == UserRole.tenant) {
        if (cccd == null || cccd.isEmpty) {
          throw const ValidationFailure(message: 'CCCD không được để trống.');
        }

        final encryptedCccd = await _encryptionService.encryptText(cccd);

        // Tìm trong bảng khachthue xem có CCCD này không bằng RPC (vượt qua RLS)
        final response = await _client
            .rpc('check_tenant_cccd', params: {'p_encrypted_cccd': encryptedCccd});

        if (response == null) {
          throw const ValidationFailure(
              message: 'Không tìm thấy thông tin hợp đồng thuê khớp với CCCD này. Vui lòng liên hệ chủ trọ!');
        }
        
        tenantData = response as Map<String, dynamic>;
      }

      // 2. Đăng ký tài khoản với Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'quyenhan': role.code,
        },
      );

      if (response.user == null) {
        throw const AuthFailure(message: 'Đăng ký thất bại.');
      }

      // Việc insert vào bảng users được thực hiện tự động qua Trigger handle_new_user trong Supabase.
      
      // 3. Liên kết tài khoản cho Khách thuê
      if (role == UserRole.tenant && tenantData != null) {
        final userId = response.user!.id;
        final tenantId = tenantData['id'];
        final roomId = tenantData['room_id'];
        final propertyId = tenantData['property_id'];

        // Đợi 1 chút để trigger bên Supabase insert xong vào bảng users
        await Future.delayed(const Duration(milliseconds: 500));

        // Cập nhật bảng users
        await _client.from(AppConstants.tableUsers).update({
          'room_id': roomId,
          'property_id': propertyId,
        }).eq('iduser', userId);

        // Cập nhật bảng khachthue thông qua RPC để vượt qua RLS
        await _client.rpc('link_tenant_to_user', params: {
          'p_tenant_id': tenantId,
          'p_user_id': userId,
          'p_phone': phone,
          'p_email': email,
        });
      }

      // 4. Tạo nhà trọ và subscription cho Chủ trọ mới
      if (role == UserRole.owner) {
        final userId = response.user!.id;
        await Future.delayed(const Duration(milliseconds: 500));

        // Tạo nhà trọ với trạng thái PENDING (chờ duyệt)
        final nhaTroRes = await _client
            .from('nhatro')
            .insert({
              'name': fullName, // Tạm dùng tên chủ trọ, setup_property sẽ cập nhật sau
              'iduser': userId,
              'registration_status': 'PENDING',
            })
            .select()
            .single();

        final propertyId = nhaTroRes['id'] as String;

        // Gắn property_id vào users
        await _client.from(AppConstants.tableUsers).update({
          'property_id': propertyId,
        }).eq('iduser', userId);

        // Tạo subscription tùy theo gói đã chọn
        final trialEndsAt = DateTime.now().add(const Duration(days: 7));
        int maxRooms = 10;
        int price = 49000;
        String planCode = 'BASIC';

        if (plan != null) {
          if (plan.contains('Tiêu chuẩn')) {
            planCode = 'STANDARD';
            maxRooms = 30;
            price = 99000;
          } else if (plan.contains('Chuyên nghiệp')) {
            planCode = 'PRO';
            maxRooms = -1; // Unlimited
            price = 199000;
          }
        }

        await _client.from('subscriptions').insert({
          'owner_id': userId,
          'property_id': propertyId,
          'plan': planCode,
          'status': 'PENDING',
          'trial_ends_at': trialEndsAt.toIso8601String(),
          'max_rooms': maxRooms,
          'price_per_month': price,
        });
      }


      await _storage.write(key: 'last_login_time', value: DateTime.now().toIso8601String());

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
    await _storage.delete(key: 'last_login_time');
    await _client.auth.signOut();
  }

  @override
  Future<UserModel?> checkSession() async {
    final session = _client.auth.currentSession;
    if (session == null || _client.auth.currentUser == null) {
      return null;
    }
    
    final lastLoginStr = await _storage.read(key: 'last_login_time');
    if (lastLoginStr != null) {
      final lastLogin = DateTime.tryParse(lastLoginStr);
      if (lastLogin != null && DateTime.now().difference(lastLogin).inMinutes >= 5) {
        await logout();
        return null;
      }
    } else {
      await logout();
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
  Future<UserModel> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    try {
      await _client
          .from(AppConstants.tableUsers)
          .update({
            'tenuser': fullName,
            'sdt': phone,
            'ngaycapnhat': DateTime.now().toIso8601String(),
          })
          .eq('iduser', userId);
          
      // Cập nhật Auth metadata trên Supabase (tùy chọn)
      await _client.auth.updateUser(
        sb.UserAttributes(
          data: {
            'full_name': fullName,
            'phone': phone,
          },
        ),
      );

      return _fetchUserProfile(userId);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
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
    // Join với nhatro để lấy registration_status của chủ trọ
    final data = await _client
        .from(AppConstants.tableUsers)
        .select('*, nhatro!fk_users_nhatro(registration_status)')
        .eq('iduser', userId)
        .single();

    // Flatten registration_status từ nested join
    final nhaTro = data['nhatro'] as Map<String, dynamic>?;
    final Map<String, dynamic> flatData = {
      ...data,
      if (nhaTro != null)
        'registration_status': nhaTro['registration_status'],
    };

    return UserModel.fromJson(flatData);
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
