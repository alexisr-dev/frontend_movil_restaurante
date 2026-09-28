import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/modelos.dart';
import '../data/pedidos_repository.dart';

class PedidosController extends ChangeNotifier {
  PedidosController(this._repositorio);

  final PedidosRepository _repositorio;
  final _aleatorio = Random.secure();

  List<Producto> productos = [];
  List<Pedido> misPedidos = [];
  final List<ItemCarrito> carrito = [];

  bool cargando = false;
  bool enviando = false;
  String? error;

  /// La clave se fija al abrir el carrito, no al enviarlo: si el envio falla y
  /// el mesero reintenta, viaja la misma clave y el backend no duplica nada.
  String? _claveIdempotencia;

  int get totalItems => carrito.fold(0, (suma, item) => suma + item.cantidad);
  double get totalCarrito => carrito.fold(0, (suma, item) => suma + item.subtotal);

  Map<String, List<Producto>> get porCategoria {
    final agrupado = <String, List<Producto>>{};
    for (final producto in productos) {
      agrupado.putIfAbsent(producto.categoriaNombre, () => []).add(producto);
    }
    return agrupado;
  }

  Future<void> cargarProductos() async {
    cargando = true;
    error = null;
    notifyListeners();

    try {
      productos = await _repositorio.productos();
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarMisPedidos() async {
    cargando = true;
    error = null;
    notifyListeners();

    try {
      misPedidos = await _repositorio.mios();
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void iniciarCarrito() {
    carrito.clear();
    _claveIdempotencia = _generarUuid();
    error = null;
    notifyListeners();
  }

  void agregar(Producto producto) {
    final existente = carrito.where((item) => item.producto.id == producto.id).firstOrNull;
    if (existente != null) {
      existente.cantidad++;
    } else {
      carrito.add(ItemCarrito(producto: producto));
    }
    notifyListeners();
  }

  void quitar(Producto producto) {
    final existente = carrito.where((item) => item.producto.id == producto.id).firstOrNull;
    if (existente == null) return;
    existente.cantidad--;
    if (existente.cantidad <= 0) carrito.remove(existente);
    notifyListeners();
  }

  int cantidadDe(Producto producto) =>
      carrito.where((item) => item.producto.id == producto.id).firstOrNull?.cantidad ?? 0;

  void anotar(Producto producto, String notas) {
    carrito.where((item) => item.producto.id == producto.id).firstOrNull?.notas = notas;
    notifyListeners();
  }

  Future<Pedido?> enviar(int mesaId) async {
    if (carrito.isEmpty) return null;

    enviando = true;
    error = null;
    notifyListeners();

    try {
      final pedido = await _repositorio.crear(
        mesaId: mesaId,
        idempotencyKey: _claveIdempotencia ??= _generarUuid(),
        items: List.of(carrito),
      );
      carrito.clear();
      _claveIdempotencia = null;
      return pedido;
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
      return null;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarEstado(String pedidoId, String estado) async {
    try {
      final actualizado = await _repositorio.cambiarEstado(pedidoId, estado);
      final indice = misPedidos.indexWhere((pedido) => pedido.id == pedidoId);
      if (indice >= 0) misPedidos[indice] = actualizado;
      notifyListeners();
      return true;
    } on ApiError catch (fallo) {
      error = fallo.mensaje;
      notifyListeners();
      return false;
    }
  }

  String _generarUuid() {
    final bytes = List<int>.generate(16, (_) => _aleatorio.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
        '-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

extension _Primero<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
