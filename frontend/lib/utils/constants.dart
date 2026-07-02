import 'package:flutter/foundation.dart';

class Constants {
  // 🌐 URL an'ny server Render
  static const String cloudUrl = 'https://docarchive-api.onrender.com/api';

  static String get apiBaseUrl {
    // 🔍 Mampiasa 'kReleaseMode' fa tsy 'kDebugMode' mba tsy diso
    // Raha release (APK) => cloudUrl, raha debug => local
    if (kReleaseMode) {
      // Production (APK release + Web deployed)
      return cloudUrl;
    } else {
      // Local development
      if (kIsWeb) {
        return 'http://localhost:8000/api';
      } else {
        return 'http://192.168.43.33:8000/api';
      }
    }
  }
}