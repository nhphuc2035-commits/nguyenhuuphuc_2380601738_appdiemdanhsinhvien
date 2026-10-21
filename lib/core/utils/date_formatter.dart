import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class AppFormatters {
  static DateTime _parseAsVietnamTime(String rawIso) {
    final clean = rawIso.trim();
    if (clean.endsWith('Z') || clean.contains('+')) {
      return DateTime.parse(clean).toLocal();
    }
    // Server stored UtcNow without Z suffix -> parse as UTC, then convert to Vietnam Local (UTC+7)
    return DateTime.parse('${clean}Z').toLocal();
  }

  /// Format date & time to Vietnam Time (UTC+7): dd/MM/yyyy HH:mm:ss
  static String formatVietnamDateTime(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return 'Chưa ghi nhận';
    try {
      DateTime dt = _parseAsVietnamTime(rawIso);
      final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
      return formatter.format(dt);
    } catch (_) {
      final clean = rawIso.replaceFirst('T', ' ').split('.').first;
      return clean;
    }
  }

  /// Format date only: dd/MM/yyyy
  static String formatVietnamDate(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return 'N/A';
    try {
      DateTime dt = _parseAsVietnamTime(rawIso);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return rawIso.split('T').first;
    }
  }

  /// Format time only: HH:mm:ss
  static String formatVietnamTime(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return 'N/A';
    try {
      DateTime dt = _parseAsVietnamTime(rawIso);
      return DateFormat('HH:mm:ss').format(dt);
    } catch (_) {
      return rawIso.split('T').last.split('.').first;
    }
  }

  /// Shift / Ca học information according to university rules
  static String getShiftName(String? gioBatDau) {
    if (gioBatDau == null || gioBatDau.isEmpty) return 'Ca học linh hoạt';
    final parts = gioBatDau.split(':');
    if (parts.isNotEmpty) {
      final hour = int.tryParse(parts[0]) ?? 7;
      if (hour < 12) {
        return 'Ca Sáng (07:30 - 11:30)';
      } else if (hour < 18) {
        return 'Ca Chiều (12:30 - 16:30)';
      } else {
        return 'Ca Tối (18:00 - 21:30)';
      }
    }
    return 'Ca học: $gioBatDau';
  }

  /// Shift on-time rule
  static String getShiftRule(String? gioBatDau) {
    final name = getShiftName(gioBatDau);
    if (name.contains('Sáng')) {
      return 'Đúng giờ: Trước 07:30 • Qua 07:30: Đi trễ • Sau 11:30: Vắng không phép';
    } else if (name.contains('Chiều')) {
      return 'Đúng giờ: Trước 12:30 • Qua 12:30: Đi trễ • Sau 16:30: Vắng không phép';
    } else {
      return 'Đúng giờ: Trước giờ bắt đầu • Sau kết thúc ca: Vắng';
    }
  }

  /// Status Vietnamese Label
  static String getStatusLabel(String? status) {
    if (status == null) return 'Không xác định';
    final s = status.toLowerCase();
    if (s == 'comat') return 'Có mặt đúng giờ';
    if (s == 'ditre') return 'Đi trễ';
    if (s == 'vang' || s == 'vangkhongphep') return 'Vắng không phép';
    if (s == 'vangcophep') return 'Vắng có phép';
    return status;
  }

  /// Status Color
  static Color getStatusColor(String? status) {
    if (status == null) return AppTheme.textSecondary;
    final s = status.toLowerCase();
    if (s == 'comat') return AppTheme.successColor;
    if (s == 'ditre') return AppTheme.warningColor;
    if (s == 'vang' || s == 'vangkhongphep') return AppTheme.dangerColor;
    if (s == 'vangcophep') return const Color(0xFF2563EB);
    return AppTheme.textSecondary;
  }

  /// Status Icon
  static IconData getStatusIcon(String? status) {
    if (status == null) return Icons.help_outline;
    final s = status.toLowerCase();
    if (s == 'comat') return Icons.check_circle_rounded;
    if (s == 'ditre') return Icons.access_time_filled_rounded;
    if (s == 'vang' || s == 'vangkhongphep') return Icons.cancel_rounded;
    if (s == 'vangcophep') return Icons.assignment_turned_in_rounded;
    return Icons.info_outline;
  }

  /// Method Vietnamese Label
  static String getMethodLabel(String? method) {
    if (method == null) return 'Chưa rõ';
    final m = method.toLowerCase();
    if (m.contains('vantay')) return 'Vân tay sinh trắc học';
    if (m.contains('gps')) return 'Tọa độ GPS thực tế';
    if (m.contains('qr')) return 'Mã QR lớp học';
    if (m.contains('hethong') || m.contains('tudong')) return 'Hệ thống tự động chốt vắng';
    return method;
  }

  /// Method Icon
  static IconData getMethodIcon(String? method) {
    if (method == null) return Icons.device_unknown;
    final m = method.toLowerCase();
    if (m.contains('vantay')) return Icons.fingerprint_rounded;
    if (m.contains('gps')) return Icons.location_on_rounded;
    if (m.contains('qr')) return Icons.qr_code_2_rounded;
    if (m.contains('hethong') || m.contains('tudong')) return Icons.alarm_off_rounded;
    return Icons.touch_app_rounded;
  }
}
