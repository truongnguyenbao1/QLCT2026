// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user =
          await _remoteDataSource.login(email: email, password: password);
      return Right(user);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    String? cccd,
    String? plan,
  }) async {
    try {
      final user = await _remoteDataSource.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        cccd: cccd,
        plan: plan,
      );
      return Right(user);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> checkSession() async {
    try {
      final user = await _remoteDataSource.checkSession();
      return Right(user);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    try {
      final user = await _remoteDataSource.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
      );
      return Right(user);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptPrivacyPolicy(String userId) async {
    try {
      await _remoteDataSource.acceptPrivacyPolicy(userId);
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _remoteDataSource.authStateChanges;
}
