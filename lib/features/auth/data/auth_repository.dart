import '../../../core/network/api_client.dart';
import '../../../shared/models/modelos.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<Usuario> ingresar(String email, String password) async {
    final datos = await _api.post('/api/auth/login/', cuerpo: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    await _api.guardarSesion(datos['access'] as String, datos['refresh'] as String);
    return Usuario.desdeJson(datos['usuario'] as Map<String, dynamic>);
  }

  Future<Usuario> perfil() async {
    final datos = await _api.get('/api/auth/perfil/') as Map<String, dynamic>;
    return Usuario.desdeJson(datos);
  }

  Future<void> salir() => _api.limpiarSesion();
}
