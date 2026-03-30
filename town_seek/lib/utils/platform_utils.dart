import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class PlatformUtils {
  static String getUserAgent() {
    if (kIsWeb) {
      return 'Web Browser';
    } else {
      try {
        return 'Flutter Mobile (${Platform.operatingSystem} ${Platform.operatingSystemVersion})';
      } catch (e) {
        return 'Flutter Mobile';
      }
    }
  }

  static String getDeviceType() {
    if (kIsWeb) {
      return 'Desktop'; 
    } else {
      // Simple heuristic for mobile
      return 'Mobile';
    }
  }
}
