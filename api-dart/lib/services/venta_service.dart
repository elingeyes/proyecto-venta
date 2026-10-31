import 'package:mysql_client/exception.dart';
import 'package:mysql_client/mysql_client.dart';

class VentaService {
  final MySQLConnection connection;

  VentaService(this.connection);

  Future<IResultSet> obtenerTodos() async {
    return await connection.execute(
      'SELECT id, cliente_id, fecha, total, estado FROM ventas ORDER BY id DESC',
    );
  }

  Future<IResultSet> obtenerPorId(int id) async {
    return await connection.execute(
      'SELECT id, cliente_id, fecha, total, estado FROM ventas WHERE id = :id',
      {'id': id},
    );
  }

  Future<IResultSet> obtenerConDetalle(int id) async {
    return await connection.execute(
      '''
      SELECT v.id, v.cliente_id, v.fecha, v.total, v.estado,
             dv.id AS detalle_id,
             dv.producto_id,
             p.nombre AS producto,
             dv.cantidad,
             dv.precio_unitario,
             dv.subtotal
      FROM ventas v
      LEFT JOIN detalle_venta dv ON dv.venta_id = v.id
      LEFT JOIN productos p ON p.id = dv.producto_id
      WHERE v.id = :id
      ORDER BY dv.id ASC
      ''',
      {'id': id},
    );
  }

  Future<IResultSet> crear(int clienteId, double total, String estado) async {
    return await connection.execute(
      '''
      INSERT INTO ventas (cliente_id, total, estado)
      VALUES (:cliente_id, :total, :estado)
      ''',
      {'cliente_id': clienteId, 'total': total, 'estado': estado},
    );
  }

  Future<Map<String, dynamic>> crearTransaccional({
    required int clienteId,
    required List<Map<String, dynamic>> items,
    String estado = 'pendiente',
  }) async {
    return await connection.transactional((conn) async {
      final clienteResult = await conn.execute(
        'SELECT id FROM clientes WHERE id = :id',
        {'id': clienteId},
      );

      if (clienteResult.rows.isEmpty) {
        throw MySQLClientException('Cliente no encontrado');
      }

      if (items.isEmpty) {
        throw MySQLClientException(
          'La venta debe incluir al menos un producto',
        );
      }

      double total = 0;
      final detalle = <Map<String, dynamic>>[];

      for (final item in items) {
        final productoId = int.tryParse(item['producto_id']?.toString() ?? '');
        final cantidad = int.tryParse(item['cantidad']?.toString() ?? '');

        if (productoId == null || cantidad == null || cantidad <= 0) {
          throw MySQLClientException(
            'Cada producto debe incluir producto_id y cantidad válida',
          );
        }

        final productoResult = await conn.execute(
          'SELECT id, nombre, precio FROM productos WHERE id = :id',
          {'id': productoId},
        );

        if (productoResult.rows.isEmpty) {
          throw MySQLClientException('Producto no encontrado: $productoId');
        }

        final row = productoResult.rows.first;
        final precio = double.tryParse(row.colAt(2).toString()) ?? 0;
        final subtotal = precio * cantidad;

        total += subtotal;
        detalle.add({
          'producto_id': productoId,
          'cantidad': cantidad,
          'precio_unitario': precio,
          'subtotal': subtotal,
        });
      }

      final ventaResult = await conn.execute(
        '''
        INSERT INTO ventas (cliente_id, total, estado)
        VALUES (:cliente_id, :total, :estado)
        ''',
        {'cliente_id': clienteId, 'total': total, 'estado': estado},
      );

      final ventaId = int.tryParse(ventaResult.lastInsertID.toString()) ?? 0;

      for (final item in detalle) {
        final subtotal = (item['subtotal'] as num).toDouble();
        final precioUnitario = (item['precio_unitario'] as num).toDouble();

        await conn.execute(
          '''
          INSERT INTO detalle_venta (venta_id, producto_id, cantidad, precio_unitario, subtotal)
          VALUES (:venta_id, :producto_id, :cantidad, :precio_unitario, :subtotal)
          ''',
          {
            'venta_id': ventaId,
            'producto_id': item['producto_id'],
            'cantidad': item['cantidad'],
            'precio_unitario': precioUnitario,
            'subtotal': subtotal,
          },
        );
      }

      return {
        'id': ventaId,
        'cliente_id': clienteId,
        'total': total,
        'estado': estado,
        'detalle': detalle,
      };
    });
  }

  Future<IResultSet> actualizar(
    int id,
    int clienteId,
    double total,
    String estado,
  ) async {
    return await connection.execute(
      '''
      UPDATE ventas
      SET cliente_id = :cliente_id,
          total = :total,
          estado = :estado,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = :id
      ''',
      {'id': id, 'cliente_id': clienteId, 'total': total, 'estado': estado},
    );
  }

  Future<IResultSet> eliminar(int id) async {
    return await connection.execute('DELETE FROM ventas WHERE id = :id', {
      'id': id,
    });
  }
}
