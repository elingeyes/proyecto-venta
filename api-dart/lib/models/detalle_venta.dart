class DetalleVenta {
  final int id;
  final int ventaId;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleVenta({
    required this.id,
    required this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    return DetalleVenta(
      id: map['id'] as int,
      ventaId: int.tryParse(map['venta_id']?.toString() ?? '') ?? 0,
      productoId: int.tryParse(map['producto_id']?.toString() ?? '') ?? 0,
      cantidad: int.tryParse(map['cantidad']?.toString() ?? '') ?? 0,
      precioUnitario:
          double.tryParse(map['precio_unitario']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(map['subtotal']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}
