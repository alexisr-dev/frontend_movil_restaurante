import '../../../core/network/api_client.dart';
import '../../../shared/models/modelos.dart';

class MesasRepository {
  MesasRepository(this._api);

  final ApiClient _api;

  Future<List<Mesa>> listar() async {
    final datos = await _api.get('/api/v1/mesas', fastapi: true) as List;
    return datos.map((fila) => Mesa.desdeJson(fila as Map<String, dynamic>)).toList();
  }

  Future<CuentaMesa> cuenta(int mesaId) async {
    final datos = await _api.get('/api/v1/mesas/$mesaId/cuenta', fastapi: true)
        as Map<String, dynamic>;
    return CuentaMesa.desdeJson(datos);
  }

  Future<CuentaMesa> pagar(
    int mesaId, {
    required String metodo,
    required double monto,
    String? referencia,
  }) async {
    final datos = await _api.post('/api/v1/mesas/$mesaId/pagos', fastapi: true, cuerpo: {
      'metodo': metodo,
      'monto': monto.toStringAsFixed(2),
      if (referencia != null && referencia.isNotEmpty) 'referencia_externa': referencia,
    }) as Map<String, dynamic>;
    return CuentaMesa.desdeJson(datos);
  }

  Future<CuentaMesa> liberar(int mesaId, {bool forzar = false, String? motivo}) async {
    final datos = await _api.post('/api/v1/mesas/$mesaId/liberar', fastapi: true, cuerpo: {
      'forzar': forzar,
      if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
    }) as Map<String, dynamic>;
    return CuentaMesa.desdeJson(datos);
  }
}
