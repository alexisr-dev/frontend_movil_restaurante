import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/estados.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato.dart';
import '../../../../shared/models/modelos.dart';
import '../../../../shared/widgets/comunes.dart';
import '../../../../shared/widgets/concha.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../mesas_controller.dart';

class MesasScreen extends StatefulWidget {
  const MesasScreen({super.key});

  @override
  State<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends State<MesasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mesas = context.read<MesasController>();
      mesas.cargar();
      final token = context.read<AuthController>().token;
      if (token != null) mesas.escuchar(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<MesasController>();

    return Scaffold(
      appBar: AppBar(
        leading: const BotonMenu(),
        title: const Text('Salon'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Wrap(
                spacing: 8,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Insignia(
                      key: ValueKey(controlador.enVivo),
                      texto: controlador.enVivo ? 'en vivo' : 'reconectando',
                      color: controlador.enVivo ? Paleta.limon : Paleta.aji,
                    ),
                  ),
                  Insignia(
                    texto: '${controlador.ocupadas}/${controlador.mesas.length} ocupadas',
                    color: Paleta.chicha,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controlador.cargar,
        child: Builder(
          builder: (context) {
            if (controlador.cargando && controlador.mesas.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controlador.error != null && controlador.mesas.isEmpty) {
              return ListView(children: [
                CajaError(mensaje: controlador.error!, onReintentar: controlador.cargar),
              ]);
            }
            if (controlador.mesas.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                EstadoVacio(
                  titulo: 'No hay mesas configuradas',
                  mensaje: 'Pide al administrador que registre las mesas del salon.',
                ),
              ]);
            }

            return Column(
              children: [
                _TiraResumen(mesas: controlador.mesas),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: controlador.mesas.length,
                    itemBuilder: (context, indice) => AparicionEscalonada(
                      indice: indice,
                      child: _TarjetaMesa(
                        mesa: controlador.mesas[indice],
                        onVolver: controlador.cargar,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _rotuloMesa(String estado) => switch (estado) {
      EstadoMesa.ocupada => 'Ocupada',
      EstadoMesa.reservada => 'Reservada',
      _ => 'Libre',
    };

/// Tira de conteo por estado, sobre la grilla del salon.
class _TiraResumen extends StatelessWidget {
  const _TiraResumen({required this.mesas});

  final List<Mesa> mesas;

  @override
  Widget build(BuildContext context) {
    int cuenta(String estado) => mesas.where((mesa) => mesa.estado == estado).length;

    Widget dato(String rotulo, int valor, Color color) => Expanded(
          child: Column(
            children: [
              Text('$valor',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1)),
              const SizedBox(height: 3),
              Text(rotulo.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Paleta.tenue)),
            ],
          ),
        );

    Widget separador() =>
        Container(width: 1, height: 26, color: const Color(0x141A1B2E));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Paleta.lienzo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x141A1B2E)),
      ),
      child: Row(
        children: [
          dato('Libres', cuenta(EstadoMesa.libre), Paleta.limon),
          separador(),
          dato('Ocupadas', cuenta(EstadoMesa.ocupada), Paleta.chicha),
          separador(),
          dato('Reservadas', cuenta(EstadoMesa.reservada), Paleta.aji),
        ],
      ),
    );
  }
}

class _TarjetaMesa extends StatelessWidget {
  const _TarjetaMesa({required this.mesa, required this.onVolver});

  final Mesa mesa;
  final Future<void> Function() onVolver;

  @override
  Widget build(BuildContext context) {
    final color = colorMesa(mesa.estado);
    final ocupada = mesa.estado == EstadoMesa.ocupada;
    final conConsumo = mesa.totalEnCurso > 0.009;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: ocupada ? 5 : 1,
      shadowColor: ocupada ? color : const Color(0x331A1B2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: ocupada ? color.withOpacity(0.40) : const Color(0x141A1B2E),
          width: ocupada ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        // Mesa ocupada -> cuenta y cobro. Mesa libre -> comanda nueva.
        // Al volver, la mesa pudo cambiar de estado: se recarga el salon.
        onTap: () async {
          if (ocupada) {
            await mostrarHojaCuentaMesa(context, mesaId: mesa.id, mesaNumero: mesa.numero);
          } else {
            await context.push('/pedidos/nuevo/${mesa.id}?numero=${mesa.numero}');
          }
          await onVolver();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plano de la mesa vista desde arriba, con sus sillas.
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withOpacity(ocupada ? 0.10 : 0.035), Paleta.lienzo],
                    stops: const [0, 0.7],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PlanoMesaPainter(
                          capacidad: mesa.capacidad,
                          color: color,
                          estado: mesa.estado,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${mesa.numero}',
                        style: TextStyle(
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          color: ocupada ? color : Paleta.tinta,
                        ),
                      ),
                    ),
                    // Cantidad de sillas: para ubicar la mesa de un vistazo.
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Paleta.lienzo,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x141A1B2E)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_seat_rounded,
                                size: 13, color: Paleta.tenue),
                            const SizedBox(width: 3),
                            Text(
                              '${mesa.capacidad}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Paleta.tinta,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Insignia(texto: _rotuloMesa(mesa.estado), color: color),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: conConsumo
                        ? Text(
                            soles(mesa.totalEnCurso),
                            key: ValueKey(mesa.totalEnCurso),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibuja la mesa vista en planta: una superficie central (redonda si es para
/// 4 o menos, rectangular si es mas) rodeada de sillas. Las sillas van llenas
/// cuando la mesa esta ocupada y vacias (solo contorno) cuando esta libre.
class _PlanoMesaPainter extends CustomPainter {
  _PlanoMesaPainter({
    required this.capacidad,
    required this.color,
    required this.estado,
  });

  final int capacidad;
  final Color color;
  final String estado;

  @override
  void paint(Canvas canvas, Size size) {
    final ocupada = estado == EstadoMesa.ocupada;
    final reservada = estado == EstadoMesa.reservada;
    final centro = Offset(size.width / 2, size.height / 2);
    final asientos = capacidad.clamp(1, 10);
    final redonda = capacidad <= 4;

    const sillaR = 5.0;
    const hueco = 8.0;
    const margen = sillaR * 2 + hueco + 3;
    final semiX = math.max(14.0, size.width / 2 - margen);
    final semiY = math.max(14.0, size.height / 2 - margen);
    final rMesa = math.min(semiX, semiY);

    final sillaFill = Paint()
      ..style = PaintingStyle.fill
      ..color = ocupada
          ? color
          : reservada
              ? color.withOpacity(0.28)
              : color.withOpacity(0.05);
    final sillaBorde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = ocupada ? color : color.withOpacity(0.55);

    for (var i = 0; i < asientos; i++) {
      final ang = -math.pi / 2 + 2 * math.pi * i / asientos;
      final rx = (redonda ? rMesa : semiX) + hueco + sillaR;
      final ry = (redonda ? rMesa : semiY * 0.72) + hueco + sillaR;
      final centroSilla = centro + Offset(math.cos(ang) * rx, math.sin(ang) * ry);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: centroSilla, width: sillaR * 2.3, height: sillaR * 2),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, sillaFill);
      canvas.drawRRect(rect, sillaBorde);
    }

    final mesaFill = Paint()
      ..style = PaintingStyle.fill
      ..color = ocupada
          ? color.withOpacity(0.16)
          : reservada
              ? color.withOpacity(0.09)
              : color.withOpacity(0.04);
    final mesaBorde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = ocupada ? color.withOpacity(0.65) : color.withOpacity(0.38);

    if (redonda) {
      canvas.drawCircle(centro, rMesa, mesaFill);
      canvas.drawCircle(centro, rMesa, mesaBorde);
    } else {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: centro, width: semiX * 2, height: semiY * 1.4),
        const Radius.circular(13),
      );
      canvas.drawRRect(rect, mesaFill);
      canvas.drawRRect(rect, mesaBorde);
    }
  }

  @override
  bool shouldRepaint(covariant _PlanoMesaPainter old) =>
      old.capacidad != capacidad ||
      old.color != color ||
      old.estado != estado;
}

Future<void> mostrarHojaCuentaMesa(
  BuildContext context, {
  required int mesaId,
  required int mesaNumero,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Paleta.lienzo,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _HojaCuentaMesa(mesaId: mesaId, mesaNumero: mesaNumero),
  );
}

class _HojaCuentaMesa extends StatefulWidget {
  const _HojaCuentaMesa({required this.mesaId, required this.mesaNumero});

  final int mesaId;
  final int mesaNumero;

  @override
  State<_HojaCuentaMesa> createState() => _HojaCuentaMesaState();
}

class _HojaCuentaMesaState extends State<_HojaCuentaMesa> {
  final _montoCtrl = TextEditingController();

  CuentaMesa? _cuenta;
  bool _cargando = true;
  bool _procesando = false;
  String? _error;

  String _metodo = MetodoPago.efectivo;
  int _partes = 1;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final controlador = context.read<MesasController>();
    final cuenta = await controlador.abrirCuenta(widget.mesaId);
    if (!mounted) return;
    setState(() {
      _cuenta = cuenta;
      _cargando = false;
      _error = cuenta == null ? (controlador.error ?? 'No se pudo abrir la cuenta') : null;
      _sugerirMonto();
    });
  }

  void _sugerirMonto() {
    final saldo = _cuenta?.saldo ?? 0;
    if (saldo <= 0) {
      _montoCtrl.text = '';
      return;
    }
    final partes = _partes < 1 ? 1 : _partes;
    _montoCtrl.text = (saldo / partes).toStringAsFixed(2);
  }

  double get _monto =>
      double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;

  void _cambiarPartes(int delta) {
    final saldo = _cuenta?.saldo ?? 0;
    final maximo = saldo <= 0 ? 1 : 12;
    setState(() {
      _partes = (_partes + delta).clamp(1, maximo);
      _sugerirMonto();
    });
  }

  Future<void> _pagar() async {
    final saldo = _cuenta?.saldo ?? 0;
    if (_monto <= 0 || _monto > saldo + 0.009) {
      setState(() => _error =
          'Ingresa un monto entre S/ 0.01 y ${soles(saldo)}');
      return;
    }
    setState(() {
      _procesando = true;
      _error = null;
    });
    final controlador = context.read<MesasController>();
    final cuenta = await controlador.registrarPago(
      widget.mesaId,
      metodo: _metodo,
      monto: _monto,
    );
    if (!mounted) return;
    setState(() {
      _procesando = false;
      if (cuenta == null) {
        _error = controlador.error ?? 'No se pudo registrar el pago';
      } else {
        _cuenta = cuenta;
        _partes = cuenta.saldada ? 1 : (_partes - 1).clamp(1, 12);
        _sugerirMonto();
      }
    });
  }

  Future<void> _liberar({bool forzar = false}) async {
    String? motivo;
    if (forzar) {
      motivo = await _pedirMotivo();
      if (motivo == null || !mounted) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final controlador = context.read<MesasController>();

    setState(() {
      _procesando = true;
      _error = null;
    });
    final cuenta = await controlador.liberar(
      widget.mesaId,
      forzar: forzar,
      motivo: motivo,
    );
    if (!mounted) return;

    if (cuenta != null && cuenta.estado == EstadoMesa.libre) {
      navegador.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Mesa ${widget.mesaNumero} liberada'),
        backgroundColor: Paleta.limon,
      ));
      return;
    }
    setState(() {
      _procesando = false;
      _error = controlador.error ?? 'No se pudo liberar la mesa';
    });
  }

  Future<String?> _pedirMotivo() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Liberar sin cobrar'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Ej: cortesia de la casa, se retiraron...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(ctrl.text.trim().isEmpty
                ? 'sin motivo'
                : ctrl.text.trim()),
            child: const Text('Liberar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = context.read<AuthController>().usuario?.rol == 'admin';
    final cuenta = _cuenta;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Mesa ${widget.mesaNumero}',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                if (cuenta != null)
                  Insignia(texto: cuenta.estado, color: colorMesa(cuenta.estado)),
              ],
            ),
            const SizedBox(height: 14),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (cuenta == null)
              Column(
                children: [
                  Text(_error ?? 'No se pudo abrir la cuenta',
                      style: const TextStyle(color: Paleta.rocoto)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _recargar, child: const Text('Reintentar')),
                ],
              )
            else ...[
              _Totales(cuenta: cuenta),
              const SizedBox(height: 14),
              if (cuenta.pedidos.isNotEmpty) ...[
                const _Rotulo('Pedidos'),
                for (final pedido in cuenta.pedidos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text('#${pedido.id.substring(0, 6)}',
                            style: const TextStyle(
                                fontFeatures: [FontFeature.tabularFigures()],
                                color: Paleta.tenue,
                                fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(rotuloEstado[pedido.estado] ?? pedido.estado,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text(
                          pedido.saldo > 0.009
                              ? soles(pedido.saldo)
                              : 'pagado',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: pedido.saldo > 0.009 ? Paleta.tinta : Paleta.limon,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
              ],
              if (cuenta.pagos.isNotEmpty) ...[
                const _Rotulo('Pagos registrados'),
                for (final pago in cuenta.pagos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(iconoMetodo(pago.metodo), size: 16, color: Paleta.tenue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pago.esCierreForzado
                                ? 'Cierre sin cobro'
                                : (rotuloMetodo[pago.metodo] ?? pago.metodo),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(soles(pago.monto),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Paleta.rocoto, fontSize: 13)),
                const SizedBox(height: 10),
              ],
              if (!cuenta.saldada) ...[
                const Divider(height: 8),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Dividir la cuenta',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      onPressed: _partes > 1 ? () => _cambiarPartes(-1) : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text('$_partes',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    IconButton(
                      onPressed: () => _cambiarPartes(1),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
                Text(
                  _partes == 1
                      ? 'Cobra el saldo completo en un pago.'
                      : 'Sugerido: ${soles((_cuenta!.saldo) / _partes)} por persona.',
                  style: const TextStyle(color: Paleta.tenue, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final metodo in MetodoPago.enApp)
                      ChoiceChip(
                        label: Text(rotuloMetodo[metodo] ?? metodo),
                        avatar: Icon(iconoMetodo(metodo), size: 18),
                        selected: _metodo == metodo,
                        onSelected: (_) => setState(() => _metodo = metodo),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: 'S/ ',
                    labelText: 'Monto a cobrar',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _procesando ? null : _pagar,
                    icon: _procesando
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white))
                        : const Icon(Icons.attach_money_rounded, size: 19),
                    label: Text(_procesando ? 'Registrando' : 'Registrar pago'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (!cuenta.saldada || _procesando) ? null : () => _liberar(),
                  style: FilledButton.styleFrom(backgroundColor: Paleta.limon),
                  icon: const Icon(Icons.check_circle_rounded, size: 19),
                  label: Text(
                    cuenta.saldada
                        ? 'Liberar mesa'
                        : 'Falta cobrar ${soles(cuenta.saldo)}',
                  ),
                ),
              ),
              if (!cuenta.saldada && esAdmin)
                Center(
                  child: TextButton(
                    onPressed: _procesando ? null : () => _liberar(forzar: true),
                    child: const Text('Liberar sin cobrar',
                        style: TextStyle(color: Paleta.rocoto)),
                  ),
                ),
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push(
                        '/pedidos/nuevo/${widget.mesaId}?numero=${widget.mesaNumero}');
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Agregar platos a la mesa'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Totales extends StatelessWidget {
  const _Totales({required this.cuenta});

  final CuentaMesa cuenta;

  @override
  Widget build(BuildContext context) {
    Widget columna(String rotulo, double valor, {Color? color}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo, style: const TextStyle(color: Paleta.tenue, fontSize: 12)),
            const SizedBox(height: 2),
            Text(soles(valor),
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: color ?? Paleta.tinta)),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Paleta.papel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          columna('Total', cuenta.total),
          columna('Pagado', cuenta.pagado),
          columna('Saldo', cuenta.saldo,
              color: cuenta.saldada ? Paleta.limon : Paleta.rocoto),
        ],
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          texto.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Paleta.tenue,
          ),
        ),
      );
}
