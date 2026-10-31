import 'dart:convert';

import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/producto_service.dart';

Router productoRoutes(MySQLConnection connection) {
  final router = Router();

  final service = ProductoService(connection);

  // GET /api/productos
  router.get('/api/productos', (Request request) async {
    final resultado = await service.obtenerTodos();

    final productos =
        resultado.rows.map((row) {
          return {
            'id': int.tryParse(row.colAt(0).toString()) ?? 0,
            'nombre': row.colAt(1),
            'precio': double.tryParse(row.colAt(2).toString()) ?? 0,
          };
        }).toList();

    return Response.ok(
      jsonEncode(productos),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // GET /api/productos/{id}
  router.get('/api/productos/<id>', (Request request) async {
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
        jsonEncode({'error': 'Producto no encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final row = resultado.rows.first;

    final producto = {
      'id': int.tryParse(row.colAt(0).toString()) ?? 0,
      'nombre': row.colAt(1),
      'precio': double.tryParse(row.colAt(2).toString()) ?? 0,
    };

    return Response.ok(
      jsonEncode(producto),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // POST /api/productos
  router.post('/api/productos', (Request request) async {
    final body = await request.readAsString();

    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return Response.badRequest(
        body: jsonEncode({'error': 'JSON inválido'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (data == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El cuerpo debe ser un objeto JSON'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final nombre = data['nombre']?.toString().trim();
    final precio = double.tryParse(data['precio']?.toString() ?? '');

    if (nombre == null || nombre.isEmpty || precio == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'nombre y precio son obligatorios'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    await service.crear(nombre, precio);

    return Response(
      201,
      body: jsonEncode({'mensaje': 'Producto creado correctamente'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // PUT /api/productos/{id}
  router.put('/api/productos/<id>', (Request request) async {
    final id = int.tryParse(request.params['id']!);

    if (id == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El ID debe ser numérico'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final body = await request.readAsString();

    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return Response.badRequest(
        body: jsonEncode({'error': 'JSON inválido'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (data == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El cuerpo debe ser un objeto JSON'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final nombre = data['nombre']?.toString().trim();
    final precio = double.tryParse(data['precio']?.toString() ?? '');

    if (nombre == null || nombre.isEmpty || precio == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'nombre y precio son obligatorios'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final resultado = await service.actualizar(id, nombre, precio);

    if (resultado.affectedRows == 0) {
      return Response.notFound(
        jsonEncode({'error': 'Producto no encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'mensaje': 'Producto actualizado correctamente'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // DELETE /api/productos/{id}
  router.delete('/api/productos/<id>', (Request request) async {
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
        jsonEncode({'error': 'Producto no encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'mensaje': 'Producto eliminado correctamente'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}
