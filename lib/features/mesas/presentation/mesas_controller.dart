import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_client.dart';
import '../../../shared/models/modelos.dart';
import '../data/mesas_repository.dart';

class MesasController extends ChangeNotifier {
  MesasController(this._repositorio);

  final MesasRepository _repositorio;

  WebsocketClient? _ws;
  StreamSubscription<Map<String, dynamic>>? _suscripcionEventos;
  StreamSubscription<bool>? _suscripcionConexion;
  Timer? _refresco;

  List<Mesa> mesas = [];
  bool cargando = false;
  bool enVivo = false;
  String? error;

  int get ocupadas => mesas.where((mesa) => mesa.estado == 'ocupada').length;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();

    try {
      mesas = await _repositorio.listar();
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Abre el canal `salon` de FastAPI para que el salón se actualice solo cuando
  /// otro mesero toma un pedido, la cocina lo mueve o alguien cobra/libera.
  void escuchar(String token) {
    if (_ws != null) return;

    _ws = WebsocketClient(canal: 'salon', token: token);

    _suscripcionConexion = _ws!.conectado.listen((estado) {
      enVivo = estado;
      notifyListeners();
    });

    _suscripcionEventos = _ws!.eventos.listen((evento) {
      switch (evento['tipo']) {
        case 'pedido.creado':
        case 'pedido.estado':
        case 'mesa.estado':
        case 'pago.registrado':
          unawaited(cargar());
      }
    });

    _ws!.conectar();

    // Respaldo: si el canal se cae, el salón no debe quedarse congelado.
    _refresco ??= Timer.periodic(const Duration(seconds: 15), (_) {
      if (!enVivo) unawaited(cargar());
    });
  }

  Future<CuentaMesa?> abrirCuenta(int mesaId) async {
    try {
      return await _repositorio.cuenta(mesaId);
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
      notifyListeners();
      return null;
    }
  }

  Future<CuentaMesa?> registrarPago(
    int mesaId, {
    required String metodo,
    required double monto,
  }) async {
    try {
      final cuenta = await _repositorio.pagar(mesaId, metodo: metodo, monto: monto);
      await cargar();
      return cuenta;
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
      notifyListeners();
      return null;
    }
  }

  Future<CuentaMesa?> liberar(int mesaId, {bool forzar = false, String? motivo}) async {
    try {
      final cuenta = await _repositorio.liberar(mesaId, forzar: forzar, motivo: motivo);
      await cargar();
      return cuenta;
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _refresco?.cancel();
    _suscripcionEventos?.cancel();
    _suscripcionConexion?.cancel();
    _ws?.cerrar();
    super.dispose();
  }
}
