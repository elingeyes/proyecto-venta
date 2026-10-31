import 'package:mysql_client/mysql_client.dart';

class ClienteService {
  final MySQLConnection connection;

  ClienteService(this.connection);

  Future<IResultSet> obtenerTodos() async {
    return await connection.execute(
      'SELECT id, nombre, apellido, telefono, email FROM clientes ORDER BY id DESC',
    );
  }

  Future<IResultSet> obtenerPorId(int id) async {
    return await connection.execute(
      'SELECT id, nombre, apellido, telefono, email FROM clientes WHERE id = :id',
      {'id': id},
    );
  }

  Future<IResultSet> crear(
    String nombre,
    String? apellido,
    String? telefono,
    String? email,
  ) async {
    return await connection.execute(
      '''
      INSERT INTO clientes (nombre, apellido, telefono, email)
      VALUES (:nombre, :apellido, :telefono, :email)
      ''',
      {
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
        'email': email,
      },
    );
  }

  Future<IResultSet> actualizar(
    int id,
    String nombre,
    String? apellido,
    String? telefono,
    String? email,
  ) async {
    return await connection.execute(
      '''
      UPDATE clientes
      SET nombre = :nombre,
          apellido = :apellido,
          telefono = :telefono,
          email = :email,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = :id
      ''',
      {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
        'email': email,
      },
    );
  }

  Future<IResultSet> eliminar(int id) async {
    return await connection.execute('DELETE FROM clientes WHERE id = :id', {
      'id': id,
    });
  }
}
