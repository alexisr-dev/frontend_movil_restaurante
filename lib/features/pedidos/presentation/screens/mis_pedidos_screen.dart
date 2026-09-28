import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/estados.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato.dart';
import '../../../../shared/models/modelos.dart';
import '../../../../shared/widgets/comunes.dart';
import '../../../../shared/widgets/concha.dart';
import '../pedidos_controller.dart';

class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({super.key});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<PedidosController>().cargarMisPedidos());
  }

  Future<void> _entregar(Pedido pedido) async {
    final controlador = context.read<PedidosController>();
    final logrado = await controlador.cambiarEstado(pedido.id, EstadoPedido.entregado);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(logrado
            ? 'Mesa ${pedido.mesaNumero}: pedido entregado'
            : controlador.error ?? 'No se pudo actualizar'),
        backgroundColor: logrado ? Paleta.limon : Paleta.rocoto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<PedidosController>();
    final pedidos = controlador.misPedidos;

    return Scaffold(
      appBar: AppBar(
        leading: const BotonMenu(),
        title: const Text('Mis pedidos'),
      ),
      body: RefreshIndicator(
        onRefresh: controlador.cargarMisPedidos,
        child: Builder(
          builder: (context) {
            if (controlador.cargando && pedidos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (pedidos.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                EstadoVacio(
                  titulo: 'Todavia no tomaste pedidos',
                  mensaje: 'Elige una mesa en el salon para empezar a tomar la comanda.',
                ),
              ]);
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: pedidos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, indice) => AparicionEscalonada(
                indice: indice,
                child: _TarjetaPedido(
                  pedido: pedidos[indice],
                  onEntregar: () => _entregar(pedidos[indice]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaPedido extends StatelessWidget {
  const _TarjetaPedido({required this.pedido, required this.onEntregar});

  final Pedido pedido;
  final VoidCallback onEntregar;

  @override
  Widget build(BuildContext context) {
    final color = colorPorEstado[pedido.estado] ?? Paleta.tenue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Mesa ${pedido.mesaNumero}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Insignia(texto: rotuloEstado[pedido.estado] ?? pedido.estado, color: color),
                const Spacer(),
                Text(hora(pedido.creadoEn),
                    style: const TextStyle(color: Paleta.tenue, fontSize: 12.5)),
              ],
            ),
            const SizedBox(height: 10),
            for (final linea in pedido.lineas)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${linea.cantidad}x',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(linea.productoNombre, style: const TextStyle(fontSize: 14)),
                    ),
                    Text(soles(linea.subtotal),
                        style: const TextStyle(color: Paleta.tenue, fontSize: 13)),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Text(soles(pedido.total),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: pedido.estado == EstadoPedido.listo
                      ? FilledButton.icon(
                          key: const ValueKey('entregar'),
                          onPressed: onEntregar,
                          style: FilledButton.styleFrom(backgroundColor: Paleta.limon),
                          icon: const Icon(Icons.room_service_rounded, size: 18),
                          label: const Text('Entregar'),
                        )
                      : Text(
                          key: ValueKey(pedido.estado),
                          antiguedad(pedido.creadoEn),
                          style: const TextStyle(color: Paleta.tenue, fontSize: 13),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
