class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  final String id;
  final String nombre;
  final String email;
  final String rol;

  bool get esMesero => rol == 'mesero' || rol == 'admin';
  bool get esCocina => rol == 'cocina' || rol == 'admin';

  factory Usuario.desdeJson(Map<String, dynamic> json) => Usuario(
        id: json['id'].toString(),
        nombre: json['nombre'] as String? ?? '',
        email: json['email'] as String? ?? '',
        rol: json['rol'] as String? ?? 'mesero',
      );
}

class Mesa {
  const Mesa({
    required this.id,
    required this.numero,
    required this.capacidad,
    required this.estado,
    required this.pedidosActivos,
    required this.totalEnCurso,
  });

  final int id;
  final int numero;
  final int capacidad;
  final String estado;
  final int pedidosActivos;
  final double totalEnCurso;

  factory Mesa.desdeJson(Map<String, dynamic> json) => Mesa(
        id: json['id'] as int,
        numero: json['numero'] as int,
        capacidad: json['capacidad'] as int,
        estado: json['estado'] as String,
        pedidosActivos: json['pedidos_activos'] as int? ?? 0,
        totalEnCurso: (json['total_en_curso'] as num?)?.toDouble() ?? 0,
      );
}

class Categoria {
  const Categoria({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory Categoria.desdeJson(Map<String, dynamic> json) =>
      Categoria(id: json['id'] as int, nombre: json['nombre'] as String);
}

class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.categoriaNombre,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String categoriaNombre;

  factory Producto.desdeJson(Map<String, dynamic> json) => Producto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String? ?? '',
        precio: double.tryParse(json['precio'].toString()) ?? 0,
        categoriaNombre: json['categoria_nombre'] as String? ?? 'Otros',
      );
}

class LineaPedido {
  const LineaPedido({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.estado,
    this.notas,
  });

  final int id;
  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String estado;
  final String? notas;

  factory LineaPedido.desdeJson(Map<String, dynamic> json) => LineaPedido(
        id: json['id'] as int,
        productoId: json['producto_id'] as int,
        productoNombre: json['producto_nombre'] as String,
        cantidad: json['cantidad'] as int,
        precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0,
        subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
        estado: json['estado'] as String,
        notas: json['notas'] as String?,
      );
}

class Pedido {
  const Pedido({
    required this.id,
    required this.mesaId,
    required this.mesaNumero,
    required this.meseroNombre,
    required this.estado,
    required this.total,
    required this.creadoEn,
    required this.lineas,
  });

  final String id;
  final int mesaId;
  final int mesaNumero;
  final String meseroNombre;
  final String estado;
  final double total;
  final DateTime creadoEn;
  final List<LineaPedido> lineas;

  int get totalItems => lineas.fold(0, (suma, linea) => suma + linea.cantidad);

  factory Pedido.desdeJson(Map<String, dynamic> json) => Pedido(
        id: json['id'] as String,
        mesaId: json['mesa_id'] as int,
        mesaNumero: json['mesa_numero'] as int,
        meseroNombre: json['mesero_nombre'] as String? ?? '',
        estado: json['estado'] as String,
        total: double.tryParse(json['total'].toString()) ?? 0,
        creadoEn: DateTime.parse(json['created_at'] as String),
        lineas: ((json['lineas'] as List?) ?? [])
            .map((linea) => LineaPedido.desdeJson(linea as Map<String, dynamic>))
            .toList(),
      );
}

class ItemCarrito {
  ItemCarrito({required this.producto, this.cantidad = 1, this.notas});

  final Producto producto;
  int cantidad;
  String? notas;

  double get subtotal => producto.precio * cantidad;
}

class PagoRegistrado {
  const PagoRegistrado({
    required this.id,
    required this.pedidoId,
    required this.metodo,
    required this.monto,
    required this.creadoEn,
    this.referenciaExterna,
  });

  final int id;
  final String pedidoId;
  final String metodo;
  final double monto;
  final DateTime creadoEn;
  final String? referenciaExterna;

  bool get esCierreForzado => (referenciaExterna ?? '').startsWith('cierre_forzado');

  factory PagoRegistrado.desdeJson(Map<String, dynamic> json) => PagoRegistrado(
        id: json['id'] as int,
        pedidoId: json['pedido_id'].toString(),
        metodo: json['metodo'] as String,
        monto: double.tryParse(json['monto'].toString()) ?? 0,
        creadoEn: DateTime.parse(json['created_at'] as String),
        referenciaExterna: json['referencia_externa'] as String?,
      );
}

class PedidoCuenta {
  const PedidoCuenta({
    required this.id,
    required this.estado,
    required this.total,
    required this.pagado,
    required this.saldo,
    required this.creadoEn,
  });

  final String id;
  final String estado;
  final double total;
  final double pagado;
  final double saldo;
  final DateTime creadoEn;

  factory PedidoCuenta.desdeJson(Map<String, dynamic> json) => PedidoCuenta(
        id: json['id'].toString(),
        estado: json['estado'] as String,
        total: double.tryParse(json['total'].toString()) ?? 0,
        pagado: double.tryParse(json['pagado'].toString()) ?? 0,
        saldo: double.tryParse(json['saldo'].toString()) ?? 0,
        creadoEn: DateTime.parse(json['created_at'] as String),
      );
}

/// La cuenta de una mesa: lo que suman sus pedidos, lo cobrado y el saldo.
class CuentaMesa {
  const CuentaMesa({
    required this.mesaId,
    required this.numero,
    required this.estado,
    required this.total,
    required this.pagado,
    required this.saldo,
    required this.pedidos,
    required this.pagos,
  });

  final int mesaId;
  final int numero;
  final String estado;
  final double total;
  final double pagado;
  final double saldo;
  final List<PedidoCuenta> pedidos;
  final List<PagoRegistrado> pagos;

  /// Con céntimos redondeados: evita que un 0.004 residual bloquee liberar.
  bool get saldada => saldo <= 0.009;

  factory CuentaMesa.desdeJson(Map<String, dynamic> json) => CuentaMesa(
        mesaId: json['mesa_id'] as int,
        numero: json['numero'] as int,
        estado: json['estado'] as String,
        total: double.tryParse(json['total'].toString()) ?? 0,
        pagado: double.tryParse(json['pagado'].toString()) ?? 0,
        saldo: double.tryParse(json['saldo'].toString()) ?? 0,
        pedidos: ((json['pedidos'] as List?) ?? [])
            .map((fila) => PedidoCuenta.desdeJson(fila as Map<String, dynamic>))
            .toList(),
        pagos: ((json['pagos'] as List?) ?? [])
            .map((fila) => PagoRegistrado.desdeJson(fila as Map<String, dynamic>))
            .toList(),
      );
}
