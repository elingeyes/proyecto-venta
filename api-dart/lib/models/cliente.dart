class Cliente {
  final int id;
  final String nombre;
  final String? apellido;
  final String? telefono;
  final String? email;

  Cliente({
    required this.id,
    required this.nombre,
    this.apellido,
    this.telefono,
    this.email,
  });

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int,
      nombre: map['nombre']?.toString() ?? '',
      apellido: map['apellido']?.toString(),
      telefono: map['telefono']?.toString(),
      email: map['email']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'email': email,
    };
  }
}