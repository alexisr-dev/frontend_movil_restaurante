import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EstadoPedido {
  static const pendiente = 'pendiente';
  static const preparando = 'preparando';
  static const listo = 'listo';
  static const entregado = 'entregado';
  static const cancelado = 'cancelado';

  static const enCocina = [pendiente, preparando, listo];
}

class EstadoMesa {
  static const libre = 'libre';
  static const ocupada = 'ocupada';
  static const reservada = 'reservada';
}

class MetodoPago {
  static const efectivo = 'efectivo';
  static const tarjeta = 'tarjeta';
  static const yape = 'yape';

  /// Los tres que el mesero puede elegir al cobrar desde la app.
  static const enApp = [efectivo, tarjeta, yape];
}

const Map<String, String> rotuloMetodo = {
  MetodoPago.efectivo: 'Efectivo',
  MetodoPago.tarjeta: 'Tarjeta',
  MetodoPago.yape: 'Yape',
  'plin': 'Plin',
  'mercado_pago': 'Mercado Pago',
};

IconData iconoMetodo(String metodo) => switch (metodo) {
      MetodoPago.efectivo => Icons.payments_rounded,
      MetodoPago.tarjeta => Icons.credit_card_rounded,
      MetodoPago.yape => Icons.qr_code_2_rounded,
      _ => Icons.account_balance_wallet_rounded,
    };

const Map<String, Color> colorPorEstado = {
  EstadoPedido.pendiente: Paleta.aji,
  EstadoPedido.preparando: Paleta.chicha,
  EstadoPedido.listo: Paleta.limon,
  EstadoPedido.entregado: Paleta.tenue,
  EstadoPedido.cancelado: Paleta.rocoto,
};

const Map<String, String> rotuloEstado = {
  EstadoPedido.pendiente: 'En espera',
  EstadoPedido.preparando: 'En preparacion',
  EstadoPedido.listo: 'Listo para servir',
  EstadoPedido.entregado: 'Entregado',
  EstadoPedido.cancelado: 'Cancelado',
};

Color colorMesa(String estado) => switch (estado) {
      EstadoMesa.ocupada => Paleta.chicha,
      EstadoMesa.reservada => Paleta.aji,
      _ => Paleta.limon,
    };
