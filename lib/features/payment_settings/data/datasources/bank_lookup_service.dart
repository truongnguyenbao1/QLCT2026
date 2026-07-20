// lib/features/payment_settings/data/datasources/bank_lookup_service.dart
// ─────────────────────────────────────────────────────────────────────────────
//  Service tra cứu tên chủ tài khoản ngân hàng qua VietQR API (Napas 247)
//
//  📌 Đăng ký API Key MIỄN PHÍ tại: https://vietqr.io/danh-sach-api/
//     Sau khi đăng ký, thay _clientId và _apiKey bên dưới.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class BankLookupService {
  // ⚠️ Thay thế bằng API Key của bạn từ https://vietqr.io/danh-sach-api/
  static const String _clientId = '399756aa-9bcc-421d-a42d-e6a0f0113d9f';
  static const String _apiKey   = '5ecf3448-db9b-4688-90c6-d27acda45eaa';

  static const String _baseUrl  = 'https://api.vietqr.io/v2';
  static const Duration _timeout = Duration(seconds: 10);

  /// Tra cứu tên chủ tài khoản qua Napas 247.
  ///
  /// [bin]           – Mã BIN 6 số của ngân hàng (VD: '970436' = Vietcombank)
  /// [accountNumber] – Số tài khoản cần tra cứu
  ///
  /// Trả về tên tài khoản (VD: 'NGUYEN VAN A') hoặc null nếu không tìm thấy.
  /// Ném [BankLookupException] nếu xảy ra lỗi mạng / API key chưa cấu hình.
  Future<String?> lookupAccountName({
    required String bin,
    required String accountNumber,
  }) async {
    // Kiểm tra API key đã cấu hình chưa
    if (_clientId == 'YOUR_CLIENT_ID' || _apiKey == 'YOUR_API_KEY') {
      throw const BankLookupException(
        'Chưa cấu hình VietQR API Key.\n'
        'Đăng ký miễn phí tại https://vietqr.io/danh-sach-api/',
      );
    }

    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final uri = Uri.parse('$_baseUrl/lookup');
      final request = await client.postUrl(uri).timeout(_timeout);

      request.headers
        ..set('Content-Type', 'application/json; charset=utf-8')
        ..set('x-client-id', _clientId)
        ..set('x-api-key', _apiKey);

      final bodyBytes = utf8.encode(jsonEncode({
        'bin': bin,
        'accountNumber': accountNumber,
      }));
      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      final response = await request.close().timeout(_timeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);

      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      if (json['code'] == '00') {
        final data = json['data'] as Map<String, dynamic>?;
        final name = data?['accountName'] as String?;
        return (name != null && name.isNotEmpty) ? name : null;
      }

      // Lỗi từ API (VD: tài khoản không tồn tại)
      final desc = json['desc'] as String? ?? 'Không tìm thấy tài khoản';
      throw BankLookupNotFoundException(desc);
    } on BankLookupNotFoundException catch (e) {
      rethrow;
    } on SocketException catch (e) {
      throw BankLookupException('Lỗi kết nối mạng: ${e.message}');
    } on TimeoutException {
      throw const BankLookupException('Tra cứu quá thời gian, thử lại sau');
    } on FormatException {
      throw const BankLookupException('Phản hồi API không hợp lệ');
    } finally {
      client.close();
    }
  }
}

/// Lỗi chung khi gọi VietQR API
class BankLookupException implements Exception {
  final String message;
  const BankLookupException(this.message);

  @override
  String toString() => message;
}

/// Tài khoản không tồn tại hoặc không hỗ trợ tra cứu
class BankLookupNotFoundException extends BankLookupException {
  const BankLookupNotFoundException(super.message);
}
