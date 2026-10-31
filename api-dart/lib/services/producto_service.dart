import 'package:mysql_client/mysql_client.dart';

class ProductoService {
  final MySQLConnection connection;

  ProductoService(this.connection);

  // GET /api/productos
  Future<IResultSet> obtenerTodos() async {
    return await connection.execute(
      'SELECT id, nombre, precio FROM productos ORDER BY id DESC',
    );
  }

  // GET /api/productos/{id}
  Future<IResultSet> obtenerPorId(int id) async {
    return await connection.execute(
      'SELECT id, nombre, precio FROM productos WHERE id = :id',
      {'id': id},
    );
  }

  // POST /api/productos
  Future<IResultSet> crear(String nombre, double precio) async {
    return await connection.execute(
      'INSERT INTO productos (nombre, precio) VALUES (:nombre, :precio)',
      {'nombre': nombre, 'precio': precio},
    );
  }

  // PUT /api/productos/{id}
  Future<IResultSet> actualizar(int id, String nombre, double precio) async {
    return await connection.execute(
      'UPDATE productos SET nombre = :nombre, precio = :precio, updated_at = CURRENT_TIMESTAMP WHERE id = :id',
      {'id': id, 'nombre': nombre, 'precio': precio},
    );
  }

  // DELETE /api/productos/{id}
  Future<IResultSet> eliminar(int id) async {
    return await connection.execute('DELETE FROM productos WHERE id = :id', {
      'id': id,
    });
  }
}
