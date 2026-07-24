// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Đăng nhập bằng email + password
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  });

  /// Đăng ký tài khoản mới
  Future<Either<Failure, AppUser>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    String? cccd,
    String? plan,
  });

  /// Đăng xuất
  Future<Either<Failure, void>> logout();

  /// Kiểm tra phiên đăng nhập hiện tại
  Future<Either<Failure, AppUser?>> checkSession();

  /// Lấy thông tin user hiện tại
  Future<Either<Failure, AppUser>> getCurrentUser();

  /// Cập nhật thông tin cá nhân
  Future<Either<Failure, AppUser>> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
  });

  /// Cập nhật chấp nhận Privacy Policy
  Future<Either<Failure, void>> acceptPrivacyPolicy(String userId);

  /// Đổi mật khẩu
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Quên mật khẩu - gửi email reset
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Stream theo dõi trạng thái auth
  Stream<AppUser?> get authStateChanges;
}
