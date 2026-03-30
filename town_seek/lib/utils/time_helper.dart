import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeHelper {
  /// Checks if the current time is between the open and close times.
  /// 
  /// [openTimeStr] and [closeTimeStr] should be in "HH:mm" (24h) or "h:mm a" (12h) format.
  /// If parsing fails or times are null, returns [defaultStatus].
  static bool isShopOpen(String? openTimeStr, String? closeTimeStr, {bool defaultStatus = false, DateTime? debugTime}) {
    if (openTimeStr == null || closeTimeStr == null || openTimeStr.isEmpty || closeTimeStr.isEmpty) {
      return defaultStatus;
    }

    try {
      final now = debugTime ?? DateTime.now();
      final openTime = parseTime(openTimeStr, now);
      final closeTime = parseTime(closeTimeStr, now);

      if (openTime == null || closeTime == null) return defaultStatus;

      // Handle overnight logic (e.g. 10 PM to 2 AM)
      if (closeTime.isBefore(openTime)) {
        return now.isAfter(openTime) || now.isBefore(closeTime);
      } else {
        return now.isAfter(openTime) && now.isBefore(closeTime);
      }
    } catch (e) {
      // debugPrint('Error parsing shop times: $e');
      return defaultStatus;
    }
  }

  static DateTime? parseTime(String timeStr, DateTime now) {
    try {
      // Try 12-hour format "h:mm a" (e.g. "10:30 PM")
      final format12 = DateFormat("h:mm a");
      final dt = format12.parse(timeStr);
      return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
    } catch (_) {
      try {
        // Try 24-hour format "HH:mm" (e.g. "22:30")
        final format24 = DateFormat("HH:mm");
        final dt = format24.parse(timeStr);
        return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
      } catch (e) {
        return null; // Failed to parse
      }
    }
  }

  static String formatTimeOfDay(TimeOfDay time, BuildContext context) {
    // Returns string like "10:30 PM"
    return time.format(context);
  }

  /// Formats a time string (HH:mm or HH:mm:ss) to 12-hour format (h:mm a).
  /// Returns original string if parsing fails.
  static String formatTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "";
    try {
      final dt = parseTime(timeStr, DateTime.now());
      if (dt != null) {
        return DateFormat("h:mm a").format(dt);
      }
    } catch (_) {}
    return timeStr;
  }

  /// Checks if the times represent a 24-hour open status.
  static bool is24Hours(String? openTimeStr, String? closeTimeStr) {
    if (openTimeStr == null || closeTimeStr == null) return false;
    final now = DateTime.now();
    final open = parseTime(openTimeStr, now);
    final close = parseTime(closeTimeStr, now);
    
    if (open == null || close == null) return false;

    // Check if open is 00:00 and close is 23:59 or 00:00 (next day implicity)
    // Common 24h representations: 00:00-23:59 or 00:00-00:00
    final isStartOfDay = open.hour == 0 && open.minute == 0;
    final isEndOfDay = (close.hour == 23 && close.minute >= 59) || (close.hour == 0 && close.minute == 0);

    return isStartOfDay && isEndOfDay;
  }
}
