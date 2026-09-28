import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/cocina/presentation/screens/cocina_screen.dart';
import '../features/mesas/presentation/screens/mesas_screen.dart';
import '../features/pedidos/presentation/screens/mis_pedidos_screen.dart';
import '../features/pedidos/presentation/screens/nuevo_pedido_screen.dart';
import '../shared/widgets/concha.dart';

GoRouter crearRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/mesas',
    refreshListenable: auth,
    redirect: (context, estado) {
      final ruta = estado.uri.path;

      if (auth.estado == EstadoSesion.comprobando) return null;
      if (auth.estado == EstadoSesion.fuera) return ruta == '/ingresar' ? null : '/ingresar';

      if (ruta == '/ingresar') {
        return (auth.usuario?.esMesero ?? false) ? '/mesas' : '/cocina';
      }

      // Un cocinero no toma pedidos y un mesero no mueve la cola de cocina.
      if (ruta.startsWith('/cocina') && !(auth.usuario?.esCocina ?? false)) return '/mesas';
      if ((ruta.startsWith('/mesas') || ruta.startsWith('/mis-pedidos') || ruta.startsWith('/pedidos')) &&
          !(auth.usuario?.esMesero ?? false)) {
        return '/cocina';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/ingresar', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, estado, child) => Concha(child: child),
        routes: [
          GoRoute(path: '/mesas', builder: (_, __) => const MesasScreen()),
          GoRoute(path: '/mis-pedidos', builder: (_, __) => const MisPedidosScreen()),
          GoRoute(path: '/cocina', builder: (_, __) => const CocinaScreen()),
        ],
      ),
      GoRoute(
        path: '/pedidos/nuevo/:mesaId',
        builder: (context, estado) => NuevoPedidoScreen(
          mesaId: int.parse(estado.pathParameters['mesaId']!),
          mesaNumero: int.tryParse(estado.uri.queryParameters['numero'] ?? '') ?? 0,
        ),
      ),
    ],
    errorBuilder: (context, estado) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${estado.uri}')),
    ),
  );
}
