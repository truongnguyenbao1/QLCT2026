// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Colors ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);        // Deep Blue
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryContainer = Color(0xFFBBDEFB);

  static const Color secondary = Color(0xFF00897B);      // Teal
  static const Color secondaryLight = Color(0xFF26A69A);
  static const Color secondaryDark = Color(0xFF00695C);
  static const Color secondaryContainer = Color(0xFFB2DFDB);

  static const Color accent = Color(0xFFFF6D00);         // Orange Accent
  static const Color accentLight = Color(0xFFFF9E40);

  // ── Semantic Colors ───────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF43A047);
  static const Color successContainer = Color(0xFFC8E6C9);

  static const Color warning = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFA726);
  static const Color warningContainer = Color(0xFFFFF9C4);

  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorContainer = Color(0xFFFFCDD2);

  static const Color info = Color(0xFF0277BD);
  static const Color infoLight = Color(0xFF039BE5);
  static const Color infoContainer = Color(0xFFB3E5FC);

  // ── Neutral / Surface ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF2F7);
  static const Color border = Color(0xFFDDE3ED);
  static const Color divider = Color(0xFFEBEFF5);

  // ── Text Colors ───────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F1729);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textTertiary = Color(0xFF718096);
  static const Color textDisabled = Color(0xFFA0AEC0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Dark Theme Colors ─────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0E1621);
  static const Color darkSurface = Color(0xFF162032);
  static const Color darkSurfaceVariant = Color(0xFF1E2D42);
  static const Color darkBorder = Color(0xFF2D3F55);
  static const Color darkTextPrimary = Color(0xFFEDF2F7);
  static const Color darkTextSecondary = Color(0xFFA0AEC0);

  // ── Room Status Colors ────────────────────────────────────────────────
  static const Color roomEmpty = Color(0xFF2E7D32);       // Xanh lá = Còn trống
  static const Color roomOccupied = Color(0xFF1565C0);    // Xanh dương = Đang thuê
  static const Color roomMaintenance = Color(0xFFF57F17); // Cam = Bảo trì

  // ── Invoice Status Colors ─────────────────────────────────────────────
  static const Color invoicePending = Color(0xFFF57F17);  // Chờ thanh toán
  static const Color invoicePaid = Color(0xFF2E7D32);     // Đã thanh toán
  static const Color invoiceOverdue = Color(0xFFC62828);  // Quá hạn
  static const Color invoicePartial = Color(0xFF6A1B9A);  // Thanh toán 1 phần

  // ── Gradient Definitions ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF00897B)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6D00), Color(0xFFFFA726)],
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D47A1), Color(0xFF0E1621)],
  );
}
