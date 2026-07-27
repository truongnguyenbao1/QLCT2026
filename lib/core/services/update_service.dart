import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String _repoUrl = 'https://api.github.com/repos/truongnguyenbao1/QLCT2026/releases/latest';

  /// Kiểm tra xem có bản cập nhật mới hay không
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(_repoUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersionTag = data['tag_name'] as String; // VD: "v1.0.5"
        final latestVersion = latestVersionTag.replaceAll('v', '');
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          // Lấy link tải file .exe
          final assets = data['assets'] as List;
          String? downloadUrl;
          for (var asset in assets) {
            if (asset['name'].toString().endsWith('.exe')) {
              downloadUrl = asset['browser_download_url'];
              break;
            }
          }

          if (downloadUrl != null) {
            return {
              'version': latestVersionTag,
              'downloadUrl': downloadUrl,
              'body': data['body'],
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra cập nhật: $e');
    }
    return null;
  }

  /// Tải file và tiến hành cài đặt
  static Future<void> downloadAndInstall(String downloadUrl, Function(double) onProgress) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}\\TroKeeper_Update.exe';
      
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);
      
      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;
      
      final file = File(savePath);
      final sink = file.openWrite();
      
      await response.stream.map((chunk) {
        downloaded += chunk.length;
        if (contentLength > 0) {
          onProgress(downloaded / contentLength);
        }
        return chunk;
      }).pipe(sink);
      
      await sink.close();
      client.close();
      
      // Chạy file cài đặt
      await Process.start(savePath, ['/SILENT']); // Có thể thêm /SILENT để cài ngầm, hoặc bỏ để hiện giao diện
      
      // Tắt ứng dụng hiện tại để cho phép đè file
      exit(0);
      
    } catch (e) {
      debugPrint('Lỗi tải và cài đặt: $e');
      throw e;
    }
  }

  /// So sánh version. Ví dụ: 1.0.4 < 1.0.5 -> true
  static bool _isNewerVersion(String current, String latest) {
    final v1 = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2 = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < 3; i++) {
      final part1 = i < v1.length ? v1[i] : 0;
      final part2 = i < v2.length ? v2[i] : 0;
      if (part2 > part1) return true;
      if (part2 < part1) return false;
    }
    return false;
  }
}
