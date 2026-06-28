import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  Usuario? _usuario;
  bool _cargando = true;
  bool _offline = false;

  Usuario? get usuario => _usuario;
  bool get cargando => _cargando;
  bool get estaAutenticado => _usuario != null;
  bool get sesionOffline => _offline;

  AuthService() {
    _cargarSesion();
  }

  Future<void> _cargarSesion() async {
    final token = await StorageService.getToken();
    if (token != null) {
      try {
        final data = await ApiService.get('/usuarios/me');
        _usuario = Usuario.fromJson(data['usuario'] ?? data);
        _offline = false;
        await StorageService.saveUserInfo(
            _usuario!.id, _usuario!.email, _usuario!.rol);
      } on ApiException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          await StorageService.clear();
          _usuario = null;
        } else {
          await _cargarSesionDesdeCache();
        }
      } on NetworkException catch (_) {
        await _cargarSesionDesdeCache();
      } catch (_) {
        await _cargarSesionDesdeCache();
      }
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> _cargarSesionDesdeCache() async {
    final info = await StorageService.getUserInfo();
    if (info['id'] != null && info['email'] != null && info['rol'] != null) {
      _usuario = Usuario(
        id: int.parse(info['id']!),
        email: info['email']!,
        rol: info['rol']!,
      );
      _offline = true;
    } else {
      // No hay datos cacheados del usuario: no se puede mantener sesión.
      _usuario = null;
    }
  }

  Future<void> login(String email, String password) async {
    final data = await ApiService.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    final token = data['token'];
    await StorageService.saveToken(token);
    final userData = data['usuario'];
    _usuario = Usuario.fromJson(userData);
    _offline = false;
    await StorageService.saveUserInfo(_usuario!.id, _usuario!.email, _usuario!.rol);
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.clear();
    _usuario = null;
    notifyListeners();
  }
}
