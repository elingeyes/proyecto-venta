class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.precio,
  });

  final int id;
  final String nombre;
  final double precio;

  factory Producto.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['id'].toString());
    final precio = double.tryParse(json['precio'].toString());

    if (id == null || precio == null || json['nombre'] == null) {
      throw const FormatException('Formato de producto inválido');
    }

    return Producto(id: id, nombre: json['nombre'].toString(), precio: precio);
  }
}
