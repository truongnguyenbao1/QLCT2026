// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart';

/// Base class cho tất cả failures (lỗi ở tầng domain)
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// ── Network Failures ──────────────────────────────────────────────────────
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
    super.code = 'NETWORK_ERROR',
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Yêu cầu bị hết thời gian. Vui lòng thử lại.',
    super.code = 'TIMEOUT',
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Lỗi máy chủ. Vui lòng thử lại sau.',
    super.code,
  });
}

// ── Auth Failures ─────────────────────────────────────────────────────────
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code = 'AUTH_ERROR'});
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'Email hoặc mật khẩu không đúng.',
    super.code = 'INVALID_CREDENTIALS',
  });
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({
    super.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    super.code = 'SESSION_EXPIRED',
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Bạn không có quyền thực hiện thao tác này.',
    super.code = 'UNAUTHORIZED',
  });
}

// ── Data Failures ─────────────────────────────────────────────────────────
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Không tìm thấy dữ liệu.',
    super.code = 'NOT_FOUND',
  });
}

class DuplicateFailure extends Failure {
  const DuplicateFailure({required super.message, super.code = 'DUPLICATE'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code = 'VALIDATION'});
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Lỗi dữ liệu cục bộ.',
    super.code = 'CACHE_ERROR',
  });
}

// ── Security Failures ─────────────────────────────────────────────────────
class EncryptionFailure extends Failure {
  const EncryptionFailure({
    super.message = 'Lỗi mã hóa dữ liệu.',
    super.code = 'ENCRYPTION_ERROR',
  });
}

class IntegrityFailure extends Failure {
  const IntegrityFailure({
    super.message = 'File đã bị thay đổi trái phép (kiểm tra toàn vẹn thất bại).',
    super.code = 'INTEGRITY_CHECK_FAILED',
  });
}

// ── Business Logic Failures ───────────────────────────────────────────────
class RoomOccupiedFailure extends Failure {
  const RoomOccupiedFailure({
    super.message = 'Phòng đang có người thuê. Không thể thực hiện thao tác này.',
    super.code = 'ROOM_OCCUPIED',
  });
}

class InvoiceAlreadyPaidFailure extends Failure {
  const InvoiceAlreadyPaidFailure({
    super.message = 'Hóa đơn này đã được thanh toán.',
    super.code = 'INVOICE_ALREADY_PAID',
  });
}

class ContractNotActiveFailure extends Failure {
  const ContractNotActiveFailure({
    super.message = 'Hợp đồng không còn hiệu lực.',
    super.code = 'CONTRACT_NOT_ACTIVE',
  });
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'Đã xảy ra lỗi không xác định.',
    super.code = 'UNEXPECTED',
  });
}
