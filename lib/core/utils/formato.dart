import 'package:intl/intl.dart';

/// En Peru el simbolo va delante y el separador decimal es el punto, que no es
/// lo que produce el patron por defecto de la configuracion regional.
final _monto = NumberFormat('#,##0.00', 'en_US');
final _hora = DateFormat('HH:mm');
final _fecha = DateFormat('dd MMM, HH:mm', 'es');

String soles(dynamic valor) => 'S/ ${_monto.format(_aDouble(valor))}';

String hora(DateTime momento) => _hora.format(momento.toLocal());

String fechaCorta(DateTime momento) => _fecha.format(momento.toLocal());

String antiguedad(DateTime desde) {
  final minutos = DateTime.now().difference(desde.toLocal()).inMinutes;
  if (minutos < 1) return 'recien';
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  return '${horas}h ${minutos % 60}m';
}

double _aDouble(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor?.toString() ?? '0') ?? 0;
}
