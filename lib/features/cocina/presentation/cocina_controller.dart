import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/estados.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_client.dart';
import '../../../shared/models/modelos.dart';
import '../data/cocina_repository.dart';

class CocinaController extends ChangeNotifier {
  CocinaController(this._repositorio);

  final CocinaRepository _repositorio;

  WebsocketClient? _ws;
  StreamSubscription<Map<String, dynamic>>? _suscripcionEventos;
  StreamSubscription<bool>? _suscripcionConexion;

  Map<String, List<Pedido>> tablero = {
    EstadoPedido.pendiente: [],
    EstadoPedido.preparando: [],
    EstadoPedido.listo: [],
  };

  Map<String, dynamic> metricas = {};
  bool cargando = false;
  bool enVivo = false;
  String? error;
  String? ultimoPedidoNuevo;

  List<Pedido> columna(String estado) => tablero[estado] ?? const [];

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();

    try {
      tablero = await _repositorio.tablero();
      metricas = await _repositorio.metricas();
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void escuchar(String token) {
    if (_ws != null) return;

    // Los streams son broadcast: hay que suscribirse antes de conectar o el
    // primer evento de conexion se pierde y la insignia se queda en "reconectando".
    _ws = WebsocketClient(canal: 'cocina', token: token);

    _suscripcionConexion = _ws!.conectado.listen((estado) {
      enVivo = estado;
      notifyListeners();
    });

    _suscripcionEventos = _ws!.eventos.listen((evento) {
      switch (evento['tipo']) {
        case 'pedido.creado':
          ultimoPedidoNuevo = (evento['datos']?['pedido']?['id']) as String?;
          unawaited(cargar());
        case 'pedido.estado':
        case 'pedido.linea.estado':
          unawaited(cargar());
      }
    });

    _ws!.conectar();
  }

  Future<bool> preparar(String pedidoId) => _mover(() => _repositorio.preparar(pedidoId));

  Future<bool> marcarListo(String pedidoId) => _mover(() => _repositorio.marcarListo(pedidoId));

  Future<bool> _mover(Future<Pedido> Function() accion) async {
    try {
      await accion();
      await cargar();
      return true;
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _suscripcionEventos?.cancel();
    _suscripcionConexion?.cancel();
    _ws?.cerrar();
    super.dispose();
  }
}
