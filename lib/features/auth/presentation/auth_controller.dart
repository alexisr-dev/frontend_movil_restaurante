import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/modelos.dart';
import '../data/auth_repository.dart';

enum EstadoSesion { comprobando, dentro, fuera }

class AuthController extends ChangeNotifier {
  AuthController(this._repositorio);

  final AuthRepository _repositorio;

  EstadoSesion estado = EstadoSesion.comprobando;
  Usuario? usuario;
  String? error;
  bool enviando = false;

  String? get token => ApiClient.instancia.token;

  Future<void> restaurar() async {
    await ApiClient.instancia.cargarSesion();
    if (ApiClient.instancia.token == null) {
      estado = EstadoSesion.fuera;
      notifyListeners();
      return;
    }
    try {
      usuario = await _repositorio.perfil();
      estado = EstadoSesion.dentro;
    } catch (_) {
      await _repositorio.salir();
      estado = EstadoSesion.fuera;
    }
    notifyListeners();
  }

  Future<bool> ingresar(String email, String password) async {
    enviando = true;
    error = null;
    notifyListeners();

    try {
      usuario = await _repositorio.ingresar(email.trim(), password);
      estado = EstadoSesion.dentro;
      return true;
    } on ApiError catch (fallo) {
      error = fallo.estado == 401 ? 'Correo o contrasena incorrectos.' : fallo.mensaje;
      return false;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }

  Future<void> salir() async {
    await _repositorio.salir();
    usuario = null;
    estado = EstadoSesion.fuera;
    notifyListeners();
  }
}
