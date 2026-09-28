import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/auth_controller.dart';

/// Llave del Scaffold del shell. Las pantallas hijas tienen su propio Scaffold,
/// asi que necesitan esta llave para abrir el cajon lateral (donde vive el
/// "Cerrar sesion") desde sus AppBar.
final GlobalKey<ScaffoldState> llaveConcha = GlobalKey<ScaffoldState>();

/// Boton hamburguesa para el `leading` de los AppBar de cada pantalla.
class BotonMenu extends StatelessWidget {
  const BotonMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      tooltip: 'Menu',
      onPressed: () => llaveConcha.currentState?.openDrawer(),
    );
  }
}

/// Contenedor con la barra inferior: las pestanas visibles dependen del rol.
class Concha extends StatelessWidget {
  const Concha({super.key, required this.child});

  final Widget child;

  static const _rutas = ['/mesas', '/mis-pedidos', '/cocina'];

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario;
    final ruta = GoRouterState.of(context).uri.path;

    final destinos = <NavigationDestination>[
      if (usuario?.esMesero ?? false)
        const NavigationDestination(
          icon: Icon(Icons.table_restaurant_outlined),
          selectedIcon: Icon(Icons.table_restaurant_rounded),
          label: 'Salon',
        ),
      if (usuario?.esMesero ?? false)
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Mis pedidos',
        ),
      if (usuario?.esCocina ?? false)
        const NavigationDestination(
          icon: Icon(Icons.soup_kitchen_outlined),
          selectedIcon: Icon(Icons.soup_kitchen_rounded),
          label: 'Cocina',
        ),
    ];

    final visibles = _rutas
        .where((destino) =>
            (destino != '/cocina' && (usuario?.esMesero ?? false)) ||
            (destino == '/cocina' && (usuario?.esCocina ?? false)))
        .toList();

    final indice = visibles.indexWhere(ruta.startsWith);

    return Scaffold(
      key: llaveConcha,
      body: child,
      drawer: _Cajon(),
      bottomNavigationBar: destinos.length < 2
          ? null
          : NavigationBar(
              selectedIndex: indice < 0 ? 0 : indice,
              onDestinationSelected: (elegido) => context.go(visibles[elegido]),
              backgroundColor: Paleta.lienzo,
              indicatorColor: Paleta.chicha.withOpacity(0.14),
              destinations: destinos,
            ),
    );
  }
}

class _Cajon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final usuario = auth.usuario;

    return Drawer(
      backgroundColor: Paleta.papel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Paleta.chicha,
                    child: Text(
                      (usuario?.nombre.isNotEmpty ?? false)
                          ? usuario!.nombre[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usuario?.nombre ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(usuario?.rol.toUpperCase() ?? '',
                            style: const TextStyle(
                                color: Paleta.tenue, fontSize: 11, letterSpacing: 1.1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Paleta.rocoto),
              title: const Text('Cerrar sesion', style: TextStyle(color: Paleta.rocoto)),
              onTap: () async {
                Navigator.of(context).pop();
                await auth.salir();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
