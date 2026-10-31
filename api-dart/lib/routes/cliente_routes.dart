import 'dart:convert';

import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/cliente_service.dart';

Router clienteRoutes(MySQLConnection connection) {
  final router = Router();
  final service = ClienteService(connection);

  router.get('/api/clientes', (Request request) async {
    final resultado = await service.obtenerTodos();

    final clientes =
        resultado.rows.map((row) {
          return {
            'id': row.colAt(0),
            'nombre': row.colAt(1),
            'apellido': row.colAt(2),
            'telefono': row.colAt(3),
            'email': row.colAt(4),
          };
        }).toList();

    return Response.ok(
      jsonEncode(clientes),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/clientes/<id>', (Request request) async {
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
        jsonEncode({'error': 'Cliente no encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final row = resultado.rows.first;
    final cliente = {
      'id': row.colAt(0),
      'nombre': row.colAt(1),
      'apellido': row.colAt(2),
      'telefono': row.colAt(3),
      'email': row.colAt(4),
    };

    return Response.ok(
      jsonEncode(cliente),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.post('/api/clientes', (Request request) async {
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

    final nombre = (data['nombre'] ?? '').toString().trim();
    if (nombre.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El nombre es obligatorio'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final apellido = data['apellido']?.toString().trim();
    final telefono = data['telefono']?.toString().trim();
    final email = data['email']?.toString().trim();

    final resultado = await service.crear(nombre, apellido, telefono, email);

    final id = int.tryParse(resultado.lastInsertID.toString());

    return Response(
      201,
      body: jsonEncode({'mensaje': 'Cliente creado correctamente', 'id': id}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.put('/api/clientes/<id>', (Request request) async {
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

    final nombre = (data['nombre'] ?? '').toString().trim();
    if (nombre.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'El nombre es obligatorio'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final resultado = await service.actualizar(
      id,
      nombre,
      data['apellido']?.toString().trim(),
      data['telefono']?.toString().trim(),
      data['email']?.toString().trim(),
    );

    if (resultado.affectedRows == 0) {
      return Response.notFound(
        jsonEncode({'error': 'Cliente no encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'mensaje': 'Cliente actualizado correctamente'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.delete('/api/clientes/<id>', (Request request) async {
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
        jsonEncode({'error': 'Cliente no encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'mensaje': 'Cliente eliminado correctamente'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}
