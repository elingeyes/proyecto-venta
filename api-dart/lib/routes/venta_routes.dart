import 'dart:convert';

import 'package:mysql_client/exception.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/venta_service.dart';

Router ventaRoutes(MySQLConnection connection) {
  final router = Router();
  final service = VentaService(connection);

  router.get('/api/ventas', (Request request) async {
    final resultado = await service.obtenerTodos();

    final ventas =
        resultado.rows.map((row) {
          return {
            'id': int.tryParse(row.colAt(0).toString()) ?? 0,
            'cliente_id': int.tryParse(row.colAt(1).toString()) ?? 0,
            'fecha': row.colAt(2),
            'total': double.tryParse(row.colAt(3).toString()) ?? 0,
            'estado': row.colAt(4),
          };
        }).toList();

    return Response.ok(
      jsonEncode(ventas),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/ventas/<id>', (Request request) async {
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
        jsonEncode({'error': 'Venta no encontrada'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final row = resultado.rows.first;
    final venta = {
      'id': int.tryParse(row.colAt(0).toString()) ?? 0,
      'cliente_id': int.tryParse(row.colAt(1).toString()) ?? 0,
      'fecha': row.colAt(2),
      'total': double.tryParse(row.colAt(3).toString()) ?? 0,
      'estado': row.colAt(4),
    };

    return Response.ok(
      jsonEncode(venta),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/ventas/<id>/detalle', (Request request) async {
    final id = int.tryParse(request.params['id']!);

    if (id == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El ID debe ser numérico'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final resultado = await service.obtenerConDetalle(id);

    if (resultado.rows.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Venta no encontrada'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final venta = {
      'id': int.tryParse(resultado.rows.first.colAt(0).toString()) ?? 0,
      'cliente_id': int.tryParse(resultado.rows.first.colAt(1).toString()) ?? 0,
      'fecha': resultado.rows.first.colAt(2),
      'total': double.tryParse(resultado.rows.first.colAt(3).toString()) ?? 0,
      'estado': resultado.rows.first.colAt(4),
    };

    final detalle =
        resultado.rows.where((row) => row.colAt(5) != null).map((row) {
          return {
            'id': int.tryParse(row.colAt(5).toString()) ?? 0,
            'producto_id': int.tryParse(row.colAt(6).toString()) ?? 0,
            'producto': row.colAt(7),
            'cantidad': int.tryParse(row.colAt(8).toString()) ?? 0,
            'precio_unitario': double.tryParse(row.colAt(9).toString()) ?? 0,
            'subtotal': double.tryParse(row.colAt(10).toString()) ?? 0,
          };
        }).toList();

    return Response.ok(
      jsonEncode({'venta': venta, 'detalle': detalle}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.post('/api/ventas', (Request request) async {
    final body = await request.readAsString();
    final decoded = jsonDecode(body);
    final data = decoded is Map ? Map<String, dynamic>.from(decoded) : null;

    if (data == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El cuerpo debe ser un objeto JSON'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final clienteId = int.tryParse(data['cliente_id']?.toString() ?? '');
    if (clienteId == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'cliente_id es obligatorio'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final total = double.tryParse(data['total']?.toString() ?? '0') ?? 0;
    final estado = (data['estado'] ?? 'pendiente').toString();

    final resultado = await service.crear(clienteId, total, estado);

    final id = int.tryParse(resultado.lastInsertID.toString());

    return Response(
      201,
      body: jsonEncode({'mensaje': 'Venta creada correctamente', 'id': id}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.post('/api/ventas/transaccional', (Request request) async {
    final body = await request.readAsString();
    final decoded = jsonDecode(body);
    final data = decoded is Map ? Map<String, dynamic>.from(decoded) : null;

    if (data == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El cuerpo debe ser un objeto JSON'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final clienteId = int.tryParse(data['cliente_id']?.toString() ?? '');
    if (clienteId == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'cliente_id es obligatorio'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final itemsRaw = data['items'];
    if (itemsRaw is! List || itemsRaw.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({
          'error': 'items debe ser una lista con al menos un producto',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final items = <Map<String, dynamic>>[];
    for (final item in itemsRaw) {
      if (item is! Map) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Cada item debe ser un objeto JSON'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      items.add(Map<String, dynamic>.from(item));
    }

    final estado = (data['estado'] ?? 'pendiente').toString();

    try {
      final resultado = await service.crearTransaccional(
        clienteId: clienteId,
        items: items,
        estado: estado,
      );

      return Response(
        201,
        body: jsonEncode({
          'mensaje': 'Venta transaccional creada correctamente',
          'venta': resultado,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } on MySQLClientException catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al procesar la venta transaccional'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  router.put('/api/ventas/<id>', (Request request) async {
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

    final clienteId = int.tryParse(data['cliente_id']?.toString() ?? '');
    if (clienteId == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'cliente_id es obligatorio'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final total = double.tryParse(data['total']?.toString() ?? '0') ?? 0;
    final estado = (data['estado'] ?? 'pendiente').toString();

    final resultado = await service.actualizar(id, clienteId, total, estado);

    if (resultado.affectedRows == 0) {
      return Response.notFound(
        jsonEncode({'error': 'Venta no encontrada'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'mensaje': 'Venta actualizada correctamente'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.delete('/api/ventas/<id>', (Request request) async {
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
        jsonEncode({'error': 'Venta no encontrada'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'mensaje': 'Venta eliminada correctamente'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}
