class Producto {
  final int id;
  final String nombre;
  final double precio;

  Producto({required this.id, required this.nombre, required this.precio});

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      precio: double.parse(map['precio'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre, 'precio': precio};
  }
}
