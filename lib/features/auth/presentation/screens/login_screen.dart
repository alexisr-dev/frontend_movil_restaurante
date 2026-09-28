import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/comunes.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _oculta = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    await context.read<AuthController>().ingresar(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AparicionEscalonada(
                  indice: 0,
                  child: Row(
                    children: [
                      Azulejo(tamano: 52, radio: 14),
                      SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sazon',
                              style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  height: 1.1)),
                          Text('Salon y cocina',
                              style: TextStyle(color: Paleta.tenue, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),
                const AparicionEscalonada(
                  indice: 1,
                  child: Text(
                    'Toma pedidos y sigue la cocina desde tu telefono',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, height: 1.2),
                  ),
                ),
                const SizedBox(height: 28),
                AparicionEscalonada(
                  indice: 2,
                  child: TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (valor) =>
                        (valor == null || !valor.contains('@')) ? 'Escribe un correo valido' : null,
                  ),
                ),
                const SizedBox(height: 14),
                AparicionEscalonada(
                  indice: 3,
                  child: TextFormField(
                    controller: _password,
                    obscureText: _oculta,
                    decoration: InputDecoration(
                      labelText: 'Contrasena',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _oculta = !_oculta),
                      ),
                    ),
                    onFieldSubmitted: (_) => _enviar(),
                    validator: (valor) =>
                        (valor == null || valor.isEmpty) ? 'Escribe tu contrasena' : null,
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: auth.error == null
                      ? const SizedBox(width: double.infinity)
                      : CajaError(mensaje: auth.error!),
                ),
                AparicionEscalonada(
                  indice: 4,
                  child: FilledButton(
                    onPressed: auth.enviando ? null : _enviar,
                    child: auth.enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 28),
                AparicionEscalonada(
                  indice: 5,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Paleta.lienzo,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x1A1A1B2E)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CUENTAS DE DEMOSTRACION',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: Paleta.tenue)),
                        SizedBox(height: 8),
                        Text('mesero@restaurante.com · Mesero2026!'),
                        Text('cocina@restaurante.com · Cocina2026!'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
