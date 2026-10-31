import 'package:mysql_client/mysql_client.dart';

class DetalleVentaService {
  final MySQLConnection connection;

  DetalleVentaService(this.connection);

  Future<IResultSet> obtenerTodos() async {
    return await connection.execute('''
      SELECT dv.id, dv.venta_id, dv.producto_id, p.nombre AS producto,
             dv.cantidad, dv.precio_unitario, dv.subtotal
      FROM detalle_venta dv
      INNER JOIN productos p ON p.id = dv.producto_id
      ORDER BY dv.id DESC
      ''');
  }

  Future<IResultSet> obtenerPorId(int id) async {
    return await connection.execute(
      '''
      SELECT dv.id, dv.venta_id, dv.producto_id, p.nombre AS producto,
             dv.cantidad, dv.precio_unitario, dv.subtotal
      FROM detalle_venta dv
      INNER JOIN productos p ON p.id = dv.producto_id
      WHERE dv.id = :id
      ''',
      {'id': id},
    );
  }

  Future<IResultSet> crear(
    int ventaId,
    int productoId,
    int cantidad,
    double precioUnitario,
  ) async {
    final subtotal = cantidad * precioUnitario;

    return await connection.execute(
      '''
      INSERT INTO detalle_venta (venta_id, producto_id, cantidad, precio_unitario, subtotal)
      VALUES (:venta_id, :producto_id, :cantidad, :precio_unitario, :subtotal)
      ''',
      {
        'venta_id': ventaId,
        'producto_id': productoId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'subtotal': subtotal,
      },
    );
  }

  Future<IResultSet> actualizar(
    int id,
    int ventaId,
    int productoId,
    int cantidad,
    double precioUnitario,
  ) async {
    final subtotal = cantidad * precioUnitario;

    return await connection.execute(
      '''
      UPDATE detalle_venta
      SET venta_id = :venta_id,
          producto_id = :producto_id,
          cantidad = :cantidad,
          precio_unitario = :precio_unitario,
          subtotal = :subtotal,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = :id
      ''',
      {
        'id': id,
        'venta_id': ventaId,
        'producto_id': productoId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'subtotal': subtotal,
      },
    );
  }

  Future<IResultSet> eliminar(int id) async {
    return await connection.execute(
      'DELETE FROM detalle_venta WHERE id = :id',
      {'id': id},
    );
  }
}
