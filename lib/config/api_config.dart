import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/storage_service.dart';

class ApiConfig {
  static const String _localhostUrl = 'http://localhost:3000/api';
  static const String _emulatorUrl = 'http://10.0.2.2:3000/api';
  static const String _defaultDeviceUrl = 'http://172.20.76.3:3000/api';

  static String _baseUrl = _emulatorUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> init() async {
    // Primero revisa si el usuario guardó una URL personalizada
    final stored = await StorageService.getServerUrl();
    if (stored != null && stored.isNotEmpty) {
      _baseUrl = stored;
      return;
    }

    // Web o escritorio (Windows/macOS/Linux): el backend corre en la misma máquina
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _baseUrl = _localhostUrl;
      return;
    }

    // Android: distingue emulador de dispositivo físico
    if (Platform.isAndroid) {
      try {
        final info = DeviceInfoPlugin();
        final android = await info.androidInfo;
        if (android.isPhysicalDevice) {
          _baseUrl = _defaultDeviceUrl;
          return;
        }
      } catch (_) {}
      _baseUrl = _emulatorUrl;
      return;
    }

    // iOS simulator
    _baseUrl = _emulatorUrl;
  }

  static Future<void> setUrl(String url) async {
    _baseUrl = url.endsWith('/api') ? url : '$url/api';
    await StorageService.saveServerUrl(_baseUrl);
  }

  static bool get esLocalhost => _baseUrl == _localhostUrl;
  static bool get esEmuladorUrl => _baseUrl == _emulatorUrl;
}
