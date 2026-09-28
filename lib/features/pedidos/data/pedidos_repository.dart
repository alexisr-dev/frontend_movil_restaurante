import '../../../core/network/api_client.dart';
import '../../../shared/models/modelos.dart';

class PedidosRepository {
  PedidosRepository(this._api);

  final ApiClient _api;

  Future<List<Producto>> productos() async {
    final datos = await _api.get('/api/catalogo/productos/', consulta: {
      'page_size': '200',
      'activo': 'true',
    }) as Map<String, dynamic>;

    return (datos['results'] as List)
        .map((fila) => Producto.desdeJson(fila as Map<String, dynamic>))
        .toList();
  }

  Future<List<Pedido>> mios() async {
    final datos = await _api.get('/api/v1/pedidos', fastapi: true, consulta: {
      'solo_mios': 'true',
      'limite': '50',
    }) as List;

    return datos.map((fila) => Pedido.desdeJson(fila as Map<String, dynamic>)).toList();
  }

  /// `idempotencyKey` viaja desde la pantalla: si el mesero toca dos veces
  /// "Enviar", el backend devuelve el mismo pedido en vez de duplicarlo.
  Future<Pedido> crear({
    required int mesaId,
    required String idempotencyKey,
    required List<ItemCarrito> items,
  }) async {
    final datos = await _api.post('/api/v1/pedidos', fastapi: true, cuerpo: {
      'mesa_id': mesaId,
      'idempotency_key': idempotencyKey,
      'lineas': items
          .map((item) => {
                'producto_id': item.producto.id,
                'cantidad': item.cantidad,
                if (item.notas != null && item.notas!.isNotEmpty) 'notas': item.notas,
              })
          .toList(),
    }) as Map<String, dynamic>;

    return Pedido.desdeJson(datos);
  }

  Future<Pedido> cambiarEstado(String pedidoId, String estado) async {
    final datos = await _api.patch('/api/v1/pedidos/$pedidoId/estado',
        fastapi: true, cuerpo: {'estado': estado}) as Map<String, dynamic>;
    return Pedido.desdeJson(datos);
  }
}
