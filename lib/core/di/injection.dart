// lib/core/di/injection.dart
// ─────────────────────────────────────────────────────────────────────────────
//  Dependency Injection configuration dùng get_it
//  Đăng ký tất cả services, repositories, BLoCs
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../security/encryption_service.dart';

// Features
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_session_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/room_management/data/datasources/room_remote_datasource.dart';
import '../../features/room_management/data/repositories/room_repository_impl.dart';
import '../../features/room_management/domain/repositories/room_repository.dart';
import '../../features/room_management/domain/usecases/get_rooms_usecase.dart';
import '../../features/room_management/domain/usecases/create_room_usecase.dart';
import '../../features/room_management/domain/usecases/update_room_usecase.dart';
import '../../features/room_management/domain/usecases/delete_room_usecase.dart';
import '../../features/room_management/presentation/bloc/room_bloc.dart';

import '../../features/tenant_management/data/datasources/tenant_remote_datasource.dart';
import '../../features/tenant_management/data/repositories/tenant_repository_impl.dart';
import '../../features/tenant_management/domain/repositories/tenant_repository.dart';
import '../../features/tenant_management/domain/usecases/get_tenants_usecase.dart';
import '../../features/tenant_management/domain/usecases/create_tenant_usecase.dart';
import '../../features/tenant_management/domain/usecases/update_tenant_usecase.dart';
import '../../features/tenant_management/domain/usecases/delete_tenant_usecase.dart';
import '../../features/tenant_management/presentation/bloc/tenant_bloc.dart';

import '../../features/invoice/data/datasources/invoice_remote_datasource.dart';
import '../../features/invoice/data/datasources/payment_remote_datasource.dart';
import '../../features/invoice/data/repositories/invoice_repository_impl.dart';
import '../../features/invoice/data/repositories/payment_repository_impl.dart';
import '../../features/invoice/domain/repositories/invoice_repository.dart';
import '../../features/invoice/domain/repositories/payment_repository.dart';
import '../../features/invoice/domain/usecases/create_invoice_usecase.dart';
import '../../features/invoice/domain/usecases/create_payment_usecase.dart';
import '../../features/invoice/domain/usecases/get_invoices_usecase.dart';
import '../../features/invoice/domain/usecases/get_invoice_by_id_usecase.dart';
import '../../features/invoice/domain/usecases/get_payments_by_invoice_usecase.dart';
import '../../features/invoice/domain/usecases/mark_invoice_paid_usecase.dart';
import '../../features/invoice/domain/usecases/update_invoice_usecase.dart';
import '../../features/invoice/domain/usecases/delete_invoice_usecase.dart';
import '../../features/invoice/presentation/bloc/invoice_bloc.dart';

import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';

import '../../features/payment_settings/data/datasources/payment_settings_remote_datasource.dart';
import '../../features/payment_settings/data/repositories/payment_settings_repository_impl.dart';
import '../../features/payment_settings/domain/repositories/payment_settings_repository.dart';
import '../../features/payment_settings/presentation/bloc/payment_settings_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ── External Dependencies ─────────────────────────────────────────────
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );

  // ── Core Services ─────────────────────────────────────────────────────
  getIt.registerLazySingleton<EncryptionService>(
    () => EncryptionService(getIt<FlutterSecureStorage>()),
  );

  // ── AUTH Feature ──────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      getIt<SupabaseClient>(),
      getIt<FlutterSecureStorage>(),
      getIt<EncryptionService>(),
    ),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(
      () => CheckSessionUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(
      () => UpdateProfileUseCase(getIt<AuthRepository>()));
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      checkSessionUseCase: getIt<CheckSessionUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      updateProfileUseCase: getIt<UpdateProfileUseCase>(),
      authDataSource: getIt<AuthRemoteDataSource>(),
    ),
  );

  // ── ROOM MANAGEMENT Feature ───────────────────────────────────────────
  getIt.registerLazySingleton<RoomRemoteDataSource>(
    () => RoomRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(getIt<RoomRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => GetRoomsUseCase(getIt<RoomRepository>()));
  getIt.registerLazySingleton(
      () => CreateRoomUseCase(getIt<RoomRepository>()));
  getIt.registerLazySingleton(
      () => UpdateRoomUseCase(getIt<RoomRepository>()));
  getIt.registerLazySingleton(
      () => DeleteRoomUseCase(getIt<RoomRepository>()));
  getIt.registerFactory<RoomBloc>(
    () => RoomBloc(
      getRoomsUseCase: getIt<GetRoomsUseCase>(),
      createRoomUseCase: getIt<CreateRoomUseCase>(),
      updateRoomUseCase: getIt<UpdateRoomUseCase>(),
      deleteRoomUseCase: getIt<DeleteRoomUseCase>(),
    ),
  );

  // ── TENANT Feature ─────────────────────────────────────────────────────
  getIt.registerLazySingleton<TenantRemoteDataSource>(
    () => TenantRemoteDataSourceImpl(
      getIt<SupabaseClient>(),
      getIt<EncryptionService>(),
    ),
  );
  getIt.registerLazySingleton<TenantRepository>(
    () => TenantRepositoryImpl(getIt<TenantRemoteDataSource>()),
  );
  getIt.registerLazySingleton(
      () => GetTenantsUseCase(getIt<TenantRepository>()));
  getIt.registerLazySingleton(
      () => CreateTenantUseCase(getIt<TenantRepository>()));
  getIt.registerLazySingleton(
      () => UpdateTenantUseCase(getIt<TenantRepository>()));
  getIt.registerLazySingleton(
      () => DeleteTenantUseCase(getIt<TenantRepository>()));
  getIt.registerFactory<TenantBloc>(
    () => TenantBloc(
      getTenantsUseCase: getIt<GetTenantsUseCase>(),
      createTenantUseCase: getIt<CreateTenantUseCase>(),
      updateTenantUseCase: getIt<UpdateTenantUseCase>(),
      deleteTenantUseCase: getIt<DeleteTenantUseCase>(),
    ),
  );

  // ── INVOICE Feature ────────────────────────────────────────────────────
  getIt.registerLazySingleton<InvoiceRemoteDataSource>(
    () => InvoiceRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(getIt<InvoiceRemoteDataSource>()),
  );
  getIt.registerLazySingleton(
      () => CreateInvoiceUseCase(getIt<InvoiceRepository>()));
  getIt.registerLazySingleton(
      () => GetInvoicesUseCase(getIt<InvoiceRepository>()));
  getIt.registerLazySingleton(
      () => GetInvoiceByIdUseCase(getIt<InvoiceRepository>()));
  getIt.registerLazySingleton(
      () => MarkInvoicePaidUseCase(getIt<InvoiceRepository>()));
  getIt.registerLazySingleton(
      () => UpdateInvoiceUseCase(getIt<InvoiceRepository>()));
  getIt.registerLazySingleton(
      () => DeleteInvoiceUseCase(getIt<InvoiceRepository>()));

  // Payment (chitiethoadon)
  getIt.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(getIt<PaymentRemoteDataSource>()),
  );
  getIt.registerLazySingleton(
      () => CreatePaymentUseCase(getIt<PaymentRepository>()));
  getIt.registerLazySingleton(
      () => GetPaymentsByInvoiceUseCase(getIt<PaymentRepository>()));

  getIt.registerFactory<InvoiceBloc>(
    () => InvoiceBloc(
      createInvoiceUseCase: getIt<CreateInvoiceUseCase>(),
      getInvoicesUseCase: getIt<GetInvoicesUseCase>(),
      getInvoiceByIdUseCase: getIt<GetInvoiceByIdUseCase>(),
      markInvoicePaidUseCase: getIt<MarkInvoicePaidUseCase>(),
      updateInvoiceUseCase: getIt<UpdateInvoiceUseCase>(),
      deleteInvoiceUseCase: getIt<DeleteInvoiceUseCase>(),
      createPaymentUseCase: getIt<CreatePaymentUseCase>(),
      getPaymentsByInvoiceUseCase: getIt<GetPaymentsByInvoiceUseCase>(),
    ),
  );

  // ── DASHBOARD Feature ──────────────────────────────────────────────────
  getIt.registerLazySingleton(
    () => GetDashboardStatsUseCase(
      getIt<RoomRepository>(),
      getIt<InvoiceRepository>(),
    ),
  );
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(getIt<GetDashboardStatsUseCase>()),
  );

  // ── PAYMENT SETTINGS Feature ──────────────────────────────────────────
  getIt.registerLazySingleton<PaymentSettingsRemoteDataSource>(
    () => PaymentSettingsRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<PaymentSettingsRepository>(
    () => PaymentSettingsRepositoryImpl(getIt<PaymentSettingsRemoteDataSource>()),
  );
  getIt.registerFactory<PaymentSettingsBloc>(
    () => PaymentSettingsBloc(getIt<PaymentSettingsRepository>()),
  );
}
