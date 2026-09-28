import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/env.dart';

/// Canal de eventos en vivo de FastAPI. Se reconecta solo con una espera
/// creciente para que la cocina no se quede sin actualizaciones tras un corte.
class WebsocketClient {
  WebsocketClient({required this.canal, required this.token});

  final String canal;
  final String token;

  WebSocketChannel? _canalWs;
  StreamSubscription<dynamic>? _suscripcion;
  Timer? _reintento;
  int _intentos = 0;
  bool _cerrado = false;

  final _eventos = StreamController<Map<String, dynamic>>.broadcast();
  final _conexion = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get eventos => _eventos.stream;
  Stream<bool> get conectado => _conexion.stream;

  void conectar() {
    if (_cerrado) return;
    final uri = Uri.parse('${Env.wsFastapi}/api/v1/ws/$canal?token=$token');

    try {
      _canalWs = WebSocketChannel.connect(uri);
      _conexion.add(true);
      _intentos = 0;

      _suscripcion = _canalWs!.stream.listen(
        (mensaje) {
          if (mensaje is! String || mensaje == 'pong') return;
          try {
            final datos = jsonDecode(mensaje);
            if (datos is Map<String, dynamic>) _eventos.add(datos);
          } catch (_) {
            // Un mensaje mal formado no debe tumbar el canal.
          }
        },
        onError: (_) => _programarReintento(),
        onDone: _programarReintento,
        cancelOnError: true,
      );
    } catch (_) {
      _programarReintento();
    }
  }

  void _programarReintento() {
    if (_cerrado) return;
    _conexion.add(false);
    _suscripcion?.cancel();
    _suscripcion = null;
    _canalWs = null;

    _intentos = (_intentos + 1).clamp(1, 6);
    _reintento?.cancel();
    _reintento = Timer(Duration(seconds: _intentos * 2), conectar);
  }

  Future<void> cerrar() async {
    _cerrado = true;
    _reintento?.cancel();
    await _suscripcion?.cancel();
    await _canalWs?.sink.close();
    await _eventos.close();
    await _conexion.close();
  }
}
