class Cliente {
  const Cliente({required this.id, required this.nombre, this.apellido});

  final int id;
  final String nombre;
  final String? apellido;

  String get nombreCompleto => [
    nombre,
    apellido,
  ].where((parte) => parte != null && parte.isNotEmpty).join(' ');

  factory Cliente.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['id'].toString());
    if (id == null || json['nombre'] == null) {
      throw const FormatException('Formato de cliente inválido');
    }
    return Cliente(
      id: id,
      nombre: json['nombre'].toString(),
      apellido: json['apellido']?.toString(),
    );
  }
}
