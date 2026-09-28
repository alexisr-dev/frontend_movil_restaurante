import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/env.dart';

class ApiError implements Exception {
  ApiError(this.mensaje, {this.codigo, this.estado});

  final String mensaje;
  final String? codigo;
  final int? estado;

  @override
  String toString() => mensaje;
}

/// Cliente compartido por los dos backends: guarda el JWT emitido por Django
/// y lo reenvia tanto a Django como a FastAPI, que comparten el mismo secreto.
class ApiClient {
  ApiClient._();

  static final ApiClient instancia = ApiClient._();

  static const _claveAcceso = 'sazon.access';
  static const _claveRefresco = 'sazon.refresh';

  String? _acceso;
  String? _refresco;

  String? get token => _acceso;

  Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    _acceso = prefs.getString(_claveAcceso);
    _refresco = prefs.getString(_claveRefresco);
  }

  Future<void> guardarSesion(String acceso, String refresco) async {
    _acceso = acceso;
    _refresco = refresco;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveAcceso, acceso);
    await prefs.setString(_claveRefresco, refresco);
  }

  Future<void> limpiarSesion() async {
    _acceso = null;
    _refresco = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveAcceso);
    await prefs.remove(_claveRefresco);
  }

  Future<dynamic> get(String ruta, {bool fastapi = false, Map<String, String>? consulta}) =>
      _enviar('GET', ruta, fastapi: fastapi, consulta: consulta);

  Future<dynamic> post(String ruta, {Object? cuerpo, bool fastapi = false}) =>
      _enviar('POST', ruta, cuerpo: cuerpo, fastapi: fastapi);

  Future<dynamic> patch(String ruta, {Object? cuerpo, bool fastapi = false}) =>
      _enviar('PATCH', ruta, cuerpo: cuerpo, fastapi: fastapi);

  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Object? cuerpo,
    bool fastapi = false,
    Map<String, String>? consulta,
    bool reintentado = false,
  }) async {
    final base = fastapi ? Env.apiFastapi : Env.apiDjango;
    final uri = Uri.parse('$base$ruta').replace(queryParameters: consulta);

    final cabeceras = <String, String>{
      'Content-Type': 'application/json',
      if (_acceso != null) 'Authorization': 'Bearer $_acceso',
    };

    final peticion = switch (metodo) {
      'GET' => http.get(uri, headers: cabeceras),
      'POST' => http.post(uri, headers: cabeceras, body: jsonEncode(cuerpo ?? {})),
      'PATCH' => http.patch(uri, headers: cabeceras, body: jsonEncode(cuerpo ?? {})),
      _ => throw ApiError('Metodo no soportado: $metodo'),
    };

    late http.Response respuesta;
    try {
      respuesta = await peticion.timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiError('No hay conexion con el servidor. Revisa la red.');
    }

    if (respuesta.statusCode == 401 && !reintentado && await _renovar()) {
      return _enviar(metodo, ruta,
          cuerpo: cuerpo, fastapi: fastapi, consulta: consulta, reintentado: true);
    }

    final texto = utf8.decode(respuesta.bodyBytes);
    final datos = texto.isEmpty ? null : jsonDecode(texto);

    if (respuesta.statusCode >= 400) {
      throw ApiError(
        _extraerMensaje(datos, respuesta.statusCode),
        codigo: datos is Map ? datos['code'] as String? : null,
        estado: respuesta.statusCode,
      );
    }

    return datos;
  }

  Future<bool> _renovar() async {
    if (_refresco == null) return false;
    try {
      final respuesta = await http.post(
        Uri.parse('${Env.apiDjango}/api/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refresco}),
      );
      if (respuesta.statusCode != 200) return false;
      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
      await guardarSesion(datos['access'] as String, _refresco!);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _extraerMensaje(dynamic datos, int estado) {
    if (datos is Map) {
      if (datos['detail'] is String) return datos['detail'] as String;
      if (datos['detail'] is List) {
        final primero = (datos['detail'] as List).first;
        if (primero is Map && primero['msg'] != null) return primero['msg'].toString();
      }
      if (datos['errors'] is Map) {
        final entrada = (datos['errors'] as Map).entries.first;
        return '${entrada.key}: ${(entrada.value as List).first}';
      }
    }
    return switch (estado) {
      401 => 'La sesion expiro. Vuelve a entrar.',
      403 => 'Tu rol no tiene permiso para esta accion.',
      404 => 'No se encontro el recurso.',
      _ => 'Error del servidor ($estado).',
    };
  }
}
