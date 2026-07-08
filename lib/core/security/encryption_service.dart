// lib/core/security/encryption_service.dart
// ─────────────────────────────────────────────────────────────────────────────
//  EncryptionService — AES-256-CBC mã hóa dữ liệu nhạy cảm (CCCD, SĐT)
//  + SHA-256 hashing để kiểm tra tính toàn vẹn của file
//  Tuân thủ: Nghị định 13/2023/NĐ-CP (bảo vệ dữ liệu cá nhân VN) & GDPR
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_constants.dart';

@lazySingleton
class EncryptionService {
  final FlutterSecureStorage _secureStorage;

  // Cache key trong memory để tránh đọc disk nhiều lần
  enc.Key? _cachedKey;
  enc.IV? _cachedIV;

  EncryptionService(this._secureStorage);

  // ── Key Management ──────────────────────────────────────────────────────

  /// Lấy hoặc tạo mới AES encryption key (256-bit = 32 bytes)
  Future<enc.Key> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;

    String? storedKey =
        await _secureStorage.read(key: AppConstants.keyEncryptionKey);

    if (storedKey == null) {
      // Tạo key ngẫu nhiên lần đầu tiên, lưu vào secure storage
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      storedKey = base64Encode(keyBytes);
      await _secureStorage.write(
        key: AppConstants.keyEncryptionKey,
        value: storedKey,
      );
    }

    _cachedKey = enc.Key(base64Decode(storedKey));
    return _cachedKey!;
  }

  /// Lấy hoặc tạo mới IV (16 bytes)
  Future<enc.IV> _getIV() async {
    if (_cachedIV != null) return _cachedIV!;

    String? storedIV =
        await _secureStorage.read(key: AppConstants.keyEncryptionIV);

    if (storedIV == null) {
      final random = Random.secure();
      final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
      storedIV = base64Encode(ivBytes);
      await _secureStorage.write(
        key: AppConstants.keyEncryptionIV,
        value: storedIV,
      );
    }

    _cachedIV = enc.IV(base64Decode(storedIV));
    return _cachedIV!;
  }

  // ── Encryption / Decryption ─────────────────────────────────────────────

  /// Mã hóa chuỗi văn bản (dùng cho CCCD, SĐT, địa chỉ nhạy cảm)
  /// Trả về chuỗi base64 đã mã hóa
  Future<String> encryptText(String plainText) async {
    try {
      final key = await _getKey();
      final iv = await _getIV();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return encrypted.base64;
    } catch (e) {
      throw EncryptionException('Mã hóa thất bại: $e');
    }
  }

  /// Giải mã chuỗi đã mã hóa
  Future<String> decryptText(String encryptedBase64) async {
    try {
      final key = await _getKey();
      final iv = await _getIV();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted =
          encrypter.decrypt(enc.Encrypted.fromBase64(encryptedBase64), iv: iv);
      return decrypted;
    } catch (e) {
      throw EncryptionException('Giải mã thất bại: $e');
    }
  }

  /// Mã hóa dữ liệu nhị phân (dùng cho ảnh CCCD)
  Future<String> encryptBytes(Uint8List bytes) async {
    final base64Data = base64Encode(bytes);
    return encryptText(base64Data);
  }

  /// Giải mã về bytes
  Future<Uint8List> decryptBytes(String encryptedBase64) async {
    final base64Data = await decryptText(encryptedBase64);
    return base64Decode(base64Data);
  }

  // ── Hashing (SHA-256) ───────────────────────────────────────────────────

  /// Tính hash SHA-256 của chuỗi văn bản
  /// Dùng để: kiểm tra toàn vẹn file hợp đồng, ảnh CCCD
  String hashText(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Tính hash SHA-256 của dữ liệu nhị phân (file bytes)
  String hashBytes(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Kiểm tra toàn vẹn: so sánh hash hiện tại với hash đã lưu
  /// Trả về true nếu file chưa bị thay đổi
  bool verifyHash(Uint8List fileBytes, String expectedHash) {
    final currentHash = hashBytes(fileBytes);
    return currentHash == expectedHash;
  }

  // ── Password Hashing ────────────────────────────────────────────────────
  // Lưu ý: Password nên dùng bcrypt/argon2 (Supabase tự xử lý)
  // Hàm này chỉ dùng cho các purpose khác như token verification

  /// Tạo HMAC-SHA256 với secret key
  String hmacSha256(String message, String secret) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(message)).toString();
  }

  // ── Anonymization (GDPR / Nghị định 13/2023) ──────────────────────────

  /// Ẩn danh hóa chuỗi nhạy cảm (CCCD) sau khi hết hợp đồng
  /// Giữ lại 4 ký tự cuối để đối chiếu nếu cần
  String anonymize(String original) {
    if (original.length <= 4) return '****';
    final lastFour = original.substring(original.length - 4);
    final masked = '*' * (original.length - 4);
    return '$masked$lastFour';
  }

  /// Xóa hoàn toàn dữ liệu nhạy cảm (thay bằng chuỗi ngẫu nhiên không phục hồi được)
  Future<String> irreversibleAnonymize() async {
    final random = Random.secure();
    final randomBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return 'ANONYMIZED_${base64Encode(randomBytes).substring(0, 16)}';
  }
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
