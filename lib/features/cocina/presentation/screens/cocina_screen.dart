import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/estados.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato.dart';
import '../../../../shared/models/modelos.dart';
import '../../../../shared/widgets/comunes.dart';
import '../../../../shared/widgets/concha.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../cocina_controller.dart';

class CocinaScreen extends StatefulWidget {
  const CocinaScreen({super.key});

  @override
  State<CocinaScreen> createState() => _CocinaScreenState();
}

class _CocinaScreenState extends State<CocinaScreen> with SingleTickerProviderStateMixin {
  late final TabController _pestanas = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cocina = context.read<CocinaController>();
      cocina.cargar();
      final token = context.read<AuthController>().token;
      if (token != null) cocina.escuchar(token);
    });
  }

  @override
  void dispose() {
    _pestanas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cocina = context.watch<CocinaController>();

    return Scaffold(
      appBar: AppBar(
        leading: const BotonMenu(),
        title: const Text('Cocina'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Insignia(
                  key: ValueKey(cocina.enVivo),
                  texto: cocina.enVivo ? 'en vivo' : 'reconectando',
                  color: cocina.enVivo ? Paleta.limon : Paleta.aji,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _pestanas,
          labelColor: Paleta.chicha,
          unselectedLabelColor: Paleta.tenue,
          indicatorColor: Paleta.chicha,
          indicatorWeight: 3,
          tabs: [
            _pestana('En espera', cocina.columna(EstadoPedido.pendiente).length),
            _pestana('Preparando', cocina.columna(EstadoPedido.preparando).length),
            _pestana('Listos', cocina.columna(EstadoPedido.listo).length),
          ],
        ),
      ),
      body: cocina.cargando && cocina.columna(EstadoPedido.pendiente).isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _pestanas,
              children: [
                _Columna(estado: EstadoPedido.pendiente, cocina: cocina),
                _Columna(estado: EstadoPedido.preparando, cocina: cocina),
                _Columna(estado: EstadoPedido.listo, cocina: cocina),
              ],
            ),
    );
  }

  Widget _pestana(String texto, int cantidad) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(texto),
          const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: cantidad > 0 ? Paleta.chicha : const Color(0x141A1B2E),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$cantidad',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: cantidad > 0 ? Colors.white : Paleta.tenue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Columna extends StatelessWidget {
  const _Columna({required this.estado, required this.cocina});

  final String estado;
  final CocinaController cocina;

  @override
  Widget build(BuildContext context) {
    final pedidos = cocina.columna(estado);

    if (pedidos.isEmpty) {
      return RefreshIndicator(
        onRefresh: cocina.cargar,
        child: ListView(children: [
          const SizedBox(height: 100),
          EstadoVacio(
            titulo: switch (estado) {
              EstadoPedido.pendiente => 'Nada en espera',
              EstadoPedido.preparando => 'Nada en preparacion',
              _ => 'Nada listo por servir',
            },
            mensaje: 'Los pedidos llegan solos: la pantalla se actualiza en vivo.',
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: cocina.cargar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        itemCount: pedidos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, indice) {
          final pedido = pedidos[indice];
          return AparicionEscalonada(
            indice: indice,
            child: PulsoAtencion(
              activo: estado == EstadoPedido.pendiente && pedido.id == cocina.ultimoPedidoNuevo,
              child: _Comanda(pedido: pedido, estado: estado, cocina: cocina),
            ),
          );
        },
      ),
    );
  }
}

class _Comanda extends StatelessWidget {
  const _Comanda({required this.pedido, required this.estado, required this.cocina});

  final Pedido pedido;
  final String estado;
  final CocinaController cocina;

  Future<void> _avanzar(BuildContext context) async {
    final logrado = estado == EstadoPedido.pendiente
        ? await cocina.preparar(pedido.id)
        : await cocina.marcarListo(pedido.id);

    if (!context.mounted || logrado) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(cocina.error ?? 'No se pudo mover el pedido')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = colorPorEstado[estado] ?? Paleta.tenue;
    final espera = DateTime.now().difference(pedido.creadoEn.toLocal()).inMinutes;
    final demorado = espera >= 15 && estado != EstadoPedido.listo;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 4, color: demorado ? Paleta.rocoto : color),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text('${pedido.mesaNumero}',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800, color: color)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${pedido.totalItems} platos',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          Text('${pedido.meseroNombre} · ${hora(pedido.creadoEn)}',
                              style: const TextStyle(color: Paleta.tenue, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Insignia(
                      texto: antiguedad(pedido.creadoEn),
                      color: demorado ? Paleta.rocoto : Paleta.tenue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final linea in pedido.lineas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text('${linea.cantidad}x',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15, color: Paleta.chicha)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(linea.productoNombre,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                              if (linea.notas != null && linea.notas!.isNotEmpty)
                                Text('· ${linea.notas}',
                                    style: const TextStyle(
                                        color: Paleta.aji,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (estado != EstadoPedido.listo) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _avanzar(context),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            estado == EstadoPedido.pendiente ? Paleta.chicha : Paleta.limon,
                      ),
                      icon: Icon(
                        estado == EstadoPedido.pendiente
                            ? Icons.local_fire_department_rounded
                            : Icons.check_circle_rounded,
                        size: 19,
                      ),
                      label: Text(estado == EstadoPedido.pendiente
                          ? 'Empezar a preparar'
                          : 'Marcar como listo'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
