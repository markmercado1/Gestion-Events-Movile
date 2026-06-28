import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userRolKey = 'user_rol';
  static const _serverUrlKey = 'server_url';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserInfo(int id, String email, String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, id);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userRolKey, rol);
  }

  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt(_userIdKey)?.toString(),
      'email': prefs.getString(_userEmailKey),
      'rol': prefs.getString(_userRolKey),
    };
  }

  static Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
  }

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    // Conserva la URL del servidor al cerrar sesión
    final serverUrl = prefs.getString(_serverUrlKey);
    await prefs.clear();
    if (serverUrl != null) await prefs.setString(_serverUrlKey, serverUrl);
  }
}
