import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Motivo de azulejo limeno: la firma visual compartida con el panel web.
class Azulejo extends StatelessWidget {
  const Azulejo({super.key, this.tamano = 44, this.radio = 12});

  final double tamano;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: Paleta.chicha,
        borderRadius: BorderRadius.circular(radio),
      ),
      child: CustomPaint(painter: _AzulejoPainter()),
    );
  }
}

class _AzulejoPainter extends CustomPainter {
  @override
  void paint(Canvas lienzo, Size medida) {
    final rombo = Paint()
      ..color = Paleta.aji
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centro = Offset(medida.width / 2, medida.height / 2);
    final radio = medida.width * 0.36;

    lienzo.drawPath(
      Path()
        ..moveTo(centro.dx, centro.dy - radio)
        ..lineTo(centro.dx + radio, centro.dy)
        ..lineTo(centro.dx, centro.dy + radio)
        ..lineTo(centro.dx - radio, centro.dy)
        ..close(),
      rombo,
    );

    lienzo.drawCircle(
      centro,
      medida.width * 0.13,
      Paint()..color = Paleta.papel,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Insignia extends StatelessWidget {
  const Insignia({super.key, required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.titulo, required this.mensaje, this.accion});

  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Opacity(opacity: 0.35, child: Azulejo(tamano: 64, radio: 16)),
            const SizedBox(height: 18),
            Text(titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Paleta.tenue, height: 1.45)),
            if (accion != null) ...[const SizedBox(height: 18), accion!],
          ],
        ),
      ),
    );
  }
}

class CajaError extends StatelessWidget {
  const CajaError({super.key, required this.mensaje, this.onReintentar});

  final String mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Paleta.rocoto.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mensaje, style: const TextStyle(color: Paleta.rocoto, fontWeight: FontWeight.w600)),
          if (onReintentar != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ],
      ),
    );
  }
}

/// Entrada escalonada: cada tarjeta aparece con un pequeno retardo segun su
/// posicion, para que la lista se lea de arriba a abajo al cargar.
class AparicionEscalonada extends StatelessWidget {
  const AparicionEscalonada({
    super.key,
    required this.indice,
    required this.child,
    this.desplazamiento = 14,
  });

  final int indice;
  final Widget child;
  final double desplazamiento;

  @override
  Widget build(BuildContext context) {
    final retardo = Duration(milliseconds: 40 * (indice.clamp(0, 10)));

    return TweenAnimationBuilder<double>(
      key: ValueKey('aparicion-$indice'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Interval(
        (retardo.inMilliseconds / 720).clamp(0, 0.6),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, valor, hijo) => Opacity(
        opacity: valor,
        child: Transform.translate(offset: Offset(0, desplazamiento * (1 - valor)), child: hijo),
      ),
      child: child,
    );
  }
}

/// Pulso suave para avisar de un pedido recien llegado a cocina.
class PulsoAtencion extends StatefulWidget {
  const PulsoAtencion({super.key, required this.activo, required this.child});

  final bool activo;
  final Widget child;

  @override
  State<PulsoAtencion> createState() => _PulsoAtencionState();
}

class _PulsoAtencionState extends State<PulsoAtencion> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.activo) _controlador.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PulsoAtencion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activo && !_controlador.isAnimating) {
      _controlador.repeat(reverse: true);
    } else if (!widget.activo && _controlador.isAnimating) {
      _controlador.stop();
      _controlador.value = 0;
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.activo) return widget.child;

    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, hijo) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Paleta.aji.withOpacity(0.34 * _controlador.value),
              blurRadius: 18,
              spreadRadius: 2 * _controlador.value,
            ),
          ],
        ),
        child: hijo,
      ),
      child: widget.child,
    );
  }
}
