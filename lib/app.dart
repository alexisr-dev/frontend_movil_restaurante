import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/cocina/data/cocina_repository.dart';
import 'features/cocina/presentation/cocina_controller.dart';
import 'features/mesas/data/mesas_repository.dart';
import 'features/mesas/presentation/mesas_controller.dart';
import 'features/pedidos/data/pedidos_repository.dart';
import 'features/pedidos/presentation/pedidos_controller.dart';
import 'routes/app_router.dart';

class RestauranteApp extends StatefulWidget {
  const RestauranteApp({super.key});

  @override
  State<RestauranteApp> createState() => _RestauranteAppState();
}

class _RestauranteAppState extends State<RestauranteApp> {
  final _api = ApiClient.instancia;
  late final AuthController _auth = AuthController(AuthRepository(_api));
  late final GoRouter _router = crearRouter(_auth);

  @override
  void initState() {
    super.initState();
    _auth.restaurar();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => MesasController(MesasRepository(_api))),
        ChangeNotifierProvider(create: (_) => PedidosController(PedidosRepository(_api))),
        ChangeNotifierProvider(create: (_) => CocinaController(CocinaRepository(_api))),
      ],
      child: MaterialApp.router(
        title: 'Sazon — Salon y cocina',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro,
        routerConfig: _router,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
