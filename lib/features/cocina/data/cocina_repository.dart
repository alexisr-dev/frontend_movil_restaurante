import '../../../core/network/api_client.dart';
import '../../../shared/models/modelos.dart';

class CocinaRepository {
  CocinaRepository(this._api);

  final ApiClient _api;

  Future<Map<String, List<Pedido>>> tablero() async {
    final datos = await _api.get('/api/v1/cocina/tablero', fastapi: true) as Map<String, dynamic>;

    return datos.map(
      (estado, pedidos) => MapEntry(
        estado,
        (pedidos as List).map((fila) => Pedido.desdeJson(fila as Map<String, dynamic>)).toList(),
      ),
    );
  }

  Future<Map<String, dynamic>> metricas() async =>
      await _api.get('/api/v1/cocina/metricas', fastapi: true) as Map<String, dynamic>;

  Future<Pedido> preparar(String pedidoId) async {
    final datos = await _api.post('/api/v1/cocina/pedidos/$pedidoId/preparar', fastapi: true)
        as Map<String, dynamic>;
    return Pedido.desdeJson(datos);
  }

  Future<Pedido> marcarListo(String pedidoId) async {
    final datos = await _api.post('/api/v1/cocina/pedidos/$pedidoId/listo', fastapi: true)
        as Map<String, dynamic>;
    return Pedido.desdeJson(datos);
  }
}
