import 'package:flutter/material.dart';
import 'app_localization.dart';

class DateFormatter {
  /// Maç zamanını formatlayarak kullanıcı dostu bir şekilde gösterir
  static String formatMatchTime(
    BuildContext context,
    DateTime? dateTime, {
    bool showTime = true,
  }) {
    if (dateTime == null) return 'TBD';

    // UTC tarih bilgisini kullanıcının yerel saat dilimine çevir
    final localDateTime = dateTime.toLocal();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final matchDate = DateTime(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day,
    );

    // Saat formatlaması
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';

    if (matchDate.isAtSameMomentAs(today)) {
      return AppLocalization.of(context)
          .translate('today_format')
          .replaceAll('{time}', showTime ? formattedTime : '');
    } else if (matchDate.isAtSameMomentAs(tomorrow)) {
      return AppLocalization.of(context)
          .translate('tomorrow_format')
          .replaceAll('{time}', showTime ? formattedTime : '');
    } else {
      return AppLocalization.of(context)
          .translate('date_format')
          .replaceAll('{day}', localDateTime.day.toString())
          .replaceAll('{month}', localDateTime.month.toString())
          .replaceAll('{year}', localDateTime.year.toString())
          .replaceAll('{time}', showTime ? formattedTime : '');
    }
  }

  /// Etkinlik tarih aralığını biçimlendirir
  static String formatDateRange(
    BuildContext context,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) {
      return AppLocalization.of(context).translate('no_date_info');
    }

    if (startDate != null && endDate == null) {
      return '${AppLocalization.of(context).translate('start_date')}: ${formatMatchTime(context, startDate, showTime: false)}';
    }

    if (startDate == null && endDate != null) {
      return '${AppLocalization.of(context).translate('end_date')}: ${formatMatchTime(context, endDate, showTime: false)}';
    }

    return '${formatMatchTime(context, startDate, showTime: false)} - ${formatMatchTime(context, endDate, showTime: false)}';
  }

  /// Basit tarih formatı (gün/ay/yıl)
  static String formatSimpleDate(DateTime? dateTime) {
    if (dateTime == null) return '-';

    final localDateTime = dateTime.toLocal();
    return '${localDateTime.day}/${localDateTime.month}/${localDateTime.year}';
  }

  /// Zaman farkını insanların okuyabileceği formata dönüştürür
  static String getTimeAgo(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "yıl" : "yıl"} önce';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "ay" : "ay"} önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? "gün" : "gün"} önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? "saat" : "saat"} önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? "dakika" : "dakika"} önce';
    } else {
      return 'Az önce';
    }
  }
}
