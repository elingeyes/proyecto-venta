class Venta {
  final int id;
  final int clienteId;
  final DateTime? fecha;
  final double total;
  final String estado;

  Venta({
    required this.id,
    required this.clienteId,
    this.fecha,
    required this.total,
    required this.estado,
  });

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int,
      clienteId: int.tryParse(map['cliente_id']?.toString() ?? '') ?? 0,
      fecha:
          map['fecha'] != null
              ? DateTime.tryParse(map['fecha'].toString())
              : null,
      total: double.tryParse(map['total']?.toString() ?? '0') ?? 0,
      estado: map['estado']?.toString() ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'fecha': fecha?.toIso8601String(),
      'total': total,
      'estado': estado,
    };
  }
}
