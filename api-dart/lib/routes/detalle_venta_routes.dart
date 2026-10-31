import 'dart:convert';

import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/detalle_venta_service.dart';

Router detalleVentaRoutes(MySQLConnection connection) {
  final router = Router();
  final service = DetalleVentaService(connection);

  router.get('/api/detalle-ventas', (Request request) async {
    final resultado = await service.obtenerTodos();

    final detalles =
        resultado.rows.map((row) {
          return {
            'id': int.tryParse(row.colAt(0).toString()) ?? 0,
            'venta_id': int.tryParse(row.colAt(1).toString()) ?? 0,
            'producto_id': int.tryParse(row.colAt(2).toString()) ?? 0,
            'producto': row.colAt(3),
            'cantidad': int.tryParse(row.colAt(4).toString()) ?? 0,
            'precio_unitario': double.tryParse(row.colAt(5).toString()) ?? 0,
            'subtotal': double.tryParse(row.colAt(6).toString()) ?? 0,
          };
        }).toList();

    return Response.ok(
      jsonEncode(detalles),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/detalle-ventas/<id>', (Request request) async {
    final id = int.tryParse(request.params['id']!);

    if (id == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El ID debe ser numérico'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final resultado = await service.obtenerPorId(id);

    if (resultado.rows.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Detalle de venta no encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final row = resultado.rows.first;
    final detalle = {
      'id': int.tryParse(row.colAt(0).toString()) ?? 0,
      'venta_id': int.tryParse(row.colAt(1).toString()) ?? 0,
      'producto_id': int.tryParse(row.colAt(2).toString()) ?? 0,
      'producto': row.colAt(3),
      'cantidad': int.tryParse(row.colAt(4).toString()) ?? 0,
      'precio_unitario': double.tryParse(row.colAt(5).toString()) ?? 0,
      'subtotal': double.tryParse(row.colAt(6).toString()) ?? 0,
    };

    return Response.ok(
      jsonEncode(detalle),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.post('/api/detalle-ventas', (Request request) async {
    final body = await request.readAsString();
    final decoded = jsonDecode(body);
    final data = decoded is Map ? Map<String, dynamic>.from(decoded) : null;

    if (data == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El cuerpo debe ser un objeto JSON'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final ventaId = int.tryParse(data['venta_id']?.toString() ?? '');
    final productoId = int.tryParse(data['producto_id']?.toString() ?? '');
    final cantidad = int.tryParse(data['cantidad']?.toString() ?? '');
    final precioUnitario = double.tryParse(
      data['precio_unitario']?.toString() ?? '',
    );

    if (ventaId == null ||
        productoId == null ||
        cantidad == null ||
        precioUnitario == null) {
      return Response.badRequest(
        body: jsonEncode({
          'error':
              'venta_id, producto_id, cantidad y precio_unitario son obligatorios',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final resultado = await service.crear(
      ventaId,
      productoId,
      cantidad,
      precioUnitario,
    );

    final id = int.tryParse(resultado.lastInsertID.toString());

    return Response(
      201,
      body: jsonEncode({
        'mensaje': 'Detalle de venta creado correctamente',
        'id': id,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.put('/api/detalle-ventas/<id>', (Request request) async {
    final id = int.tryParse(request.params['id']!);

    if (id == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El ID debe ser numérico'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final body = await request.readAsString();
    final decoded = jsonDecode(body);
    final data = decoded is Map ? Map<String, dynamic>.from(decoded) : null;

    if (data == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El cuerpo debe ser un objeto JSON'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final ventaId = int.tryParse(data['venta_id']?.toString() ?? '');
    final productoId = int.tryParse(data['producto_id']?.toString() ?? '');
    final cantidad = int.tryParse(data['cantidad']?.toString() ?? '');
    final precioUnitario = double.tryParse(
      data['precio_unitario']?.toString() ?? '',
    );

    if (ventaId == null ||
        productoId == null ||
        cantidad == null ||
        precioUnitario == null) {
      return Response.badRequest(
        body: jsonEncode({
          'error':
              'venta_id, producto_id, cantidad y precio_unitario son obligatorios',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final resultado = await service.actualizar(
      id,
      ventaId,
      productoId,
      cantidad,
      precioUnitario,
    );

    if (resultado.affectedRows == 0) {
      return Response.notFound(
        jsonEncode({'error': 'Detalle de venta no encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'mensaje': 'Detalle de venta actualizado correctamente'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.delete('/api/detalle-ventas/<id>', (Request request) async {
    final id = int.tryParse(request.params['id']!);

    if (id == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El ID debe ser numérico'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final resultado = await service.eliminar(id);

    if (resultado.affectedRows == 0) {
      return Response.notFound(
        jsonEncode({'error': 'Detalle de venta no encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'mensaje': 'Detalle de venta eliminado correctamente'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}
