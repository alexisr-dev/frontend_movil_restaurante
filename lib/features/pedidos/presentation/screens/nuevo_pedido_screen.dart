import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato.dart';
import '../../../../shared/models/modelos.dart';
import '../../../../shared/widgets/comunes.dart';
import '../pedidos_controller.dart';

class NuevoPedidoScreen extends StatefulWidget {
  const NuevoPedidoScreen({super.key, required this.mesaId, required this.mesaNumero});

  final int mesaId;
  final int mesaNumero;

  @override
  State<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}

class _NuevoPedidoScreenState extends State<NuevoPedidoScreen> {
  final _buscarCtrl = TextEditingController();
  String _busqueda = '';
  String? _categoria;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controlador = context.read<PedidosController>();
      controlador.iniciarCarrito();
      if (controlador.productos.isEmpty) controlador.cargarProductos();
    });
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final controlador = context.read<PedidosController>();
    final pedido = await controlador.enviar(widget.mesaId);
    if (!mounted) return;

    if (pedido == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controlador.error ?? 'No se pudo enviar el pedido.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido enviado a cocina · ${soles(pedido.total)}'),
        backgroundColor: Paleta.limon,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<PedidosController>();

    return Scaffold(
      appBar: AppBar(title: Text('Mesa ${widget.mesaNumero}')),
      body: Column(
        children: [
          if (controlador.productos.isNotEmpty) _filtros(controlador),
          Expanded(child: _cuerpo(controlador)),
        ],
      ),
      bottomSheet: _BarraCarrito(
        items: controlador.totalItems,
        total: controlador.totalCarrito,
        enviando: controlador.enviando,
        onEnviar: _enviar,
        onVer: () => _mostrarCarrito(context, controlador),
      ),
    );
  }

  /// Buscador + chips de categoria: mantienen usable la carta cuando crece.
  Widget _filtros(PedidosController controlador) {
    final categorias = controlador.porCategoria.keys.toList();

    return Container(
      decoration: const BoxDecoration(
        color: Paleta.papel,
        border: Border(bottom: BorderSide(color: Color(0x141A1B2E))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _buscarCtrl,
            onChanged: (valor) => setState(() => _busqueda = valor),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar plato...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _busqueda.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _buscarCtrl.clear();
                        setState(() => _busqueda = '');
                      },
                    ),
            ),
          ),
          if (categorias.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('Todas', _categoria == null,
                      () => setState(() => _categoria = null)),
                  for (final categoria in categorias)
                    _chip(categoria, _categoria == categoria,
                        () => setState(() => _categoria = categoria)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String texto, bool activo, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(texto),
          selected: activo,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: activo ? Colors.white : Paleta.tinta,
          ),
          selectedColor: Paleta.chicha,
          backgroundColor: Paleta.lienzo,
          side: BorderSide(color: activo ? Paleta.chicha : const Color(0x241A1B2E)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      );

  Widget _cuerpo(PedidosController controlador) {
    if (controlador.cargando && controlador.productos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controlador.productos.isEmpty) {
      return EstadoVacio(
        titulo: 'La carta esta vacia',
        mensaje: 'No hay productos activos para pedir.',
        accion: OutlinedButton(
          onPressed: controlador.cargarProductos,
          child: const Text('Reintentar'),
        ),
      );
    }

    final consulta = _busqueda.trim().toLowerCase();
    final agrupado = <String, List<Producto>>{};
    for (final producto in controlador.productos) {
      if (_categoria != null && producto.categoriaNombre != _categoria) continue;
      if (consulta.isNotEmpty &&
          !producto.nombre.toLowerCase().contains(consulta) &&
          !producto.descripcion.toLowerCase().contains(consulta)) {
        continue;
      }
      agrupado.putIfAbsent(producto.categoriaNombre, () => []).add(producto);
    }

    if (agrupado.isEmpty) {
      return const EstadoVacio(
        titulo: 'Sin resultados',
        mensaje: 'Ningun plato coincide con la busqueda.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
      children: [
        for (final entrada in agrupado.entries) ...[
          if (_categoria == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
              child: Text(
                entrada.key.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: Paleta.tenue,
                ),
              ),
            ),
          for (final producto in entrada.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FilaProducto(
                producto: producto,
                cantidad: controlador.cantidadDe(producto),
                onAgregar: () => controlador.agregar(producto),
                onQuitar: () => controlador.quitar(producto),
              ),
            ),
        ],
      ],
    );
  }

  void _mostrarCarrito(BuildContext context, PedidosController controlador) {
    if (controlador.carrito.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Paleta.lienzo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer<PedidosController>(
        builder: (context, ctrl, __) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detalle del pedido',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in ctrl.carrito)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.producto.nombre),
                        subtitle: Text('${item.cantidad} x ${soles(item.producto.precio)}'),
                        trailing: Text(soles(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(soles(ctrl.totalCarrito),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  const _FilaProducto({
    required this.producto,
    required this.cantidad,
    required this.onAgregar,
    required this.onQuitar,
  });

  final Producto producto;
  final int cantidad;
  final VoidCallback onAgregar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final elegido = cantidad > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Paleta.lienzo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: elegido ? Paleta.chicha : const Color(0x141A1B2E),
          width: elegido ? 1.6 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(producto.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (producto.descripcion.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      producto.descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Paleta.tenue, fontSize: 12.5),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(soles(producto.precio),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (hijo, animacion) =>
                FadeTransition(opacity: animacion, child: ScaleTransition(scale: animacion, child: hijo)),
            child: elegido
                ? Row(
                    key: const ValueKey('contador'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onQuitar,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: Paleta.rocoto,
                      ),
                      Text('$cantidad',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      IconButton(
                        onPressed: onAgregar,
                        icon: const Icon(Icons.add_circle_rounded),
                        color: Paleta.chicha,
                      ),
                    ],
                  )
                : IconButton.filledTonal(
                    key: const ValueKey('agregar'),
                    onPressed: onAgregar,
                    icon: const Icon(Icons.add_rounded),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BarraCarrito extends StatelessWidget {
  const _BarraCarrito({
    required this.items,
    required this.total,
    required this.enviando,
    required this.onEnviar,
    required this.onVer,
  });

  final int items;
  final double total;
  final bool enviando;
  final VoidCallback onEnviar;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: items == 0 ? const Offset(0, 1) : Offset.zero,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
        decoration: const BoxDecoration(
          color: Paleta.lienzo,
          border: Border(top: BorderSide(color: Color(0x141A1B2E))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onVer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$items ${items == 1 ? 'item' : 'items'}',
                          style: const TextStyle(color: Paleta.tenue, fontSize: 12.5)),
                      Text(soles(total),
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: enviando ? null : onEnviar,
                icon: enviando
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 19),
                label: Text(enviando ? 'Enviando' : 'Enviar a cocina'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
