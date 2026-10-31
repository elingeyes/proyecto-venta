import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  final port = '8080';
  final host = 'http://localhost:$port';
  late Process p;

  setUp(() async {
    p = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {'PORT': port},
    );

    await p.stdout.first;
  });

  tearDown(() async {
    if (p.kill()) {
      await p.exitCode;
    }
  });

  test('Root devuelve la API', () async {
    final response = await get(Uri.parse('$host/'));
    expect(response.statusCode, 200);
    expect(response.body, 'API Dart funcionando correctamente\n');
  });

  test('Lista productos', () async {
    final response = await get(Uri.parse('$host/api/productos'));
    expect(response.statusCode, 200);
    final decoded = jsonDecode(response.body);
    expect(decoded, isA<List>());
  });

  test('CRUD de clientes', () async {
    final unique = DateTime.now().millisecondsSinceEpoch;
    final createResponse = await post(
      Uri.parse('$host/api/clientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': 'Cliente',
        'apellido': 'Prueba',
        'telefono': '5551234',
        'email': 'cliente_$unique@test.com',
      }),
    );

    expect(createResponse.statusCode, 201);

    final createBody = jsonDecode(createResponse.body);
    final id = createBody['id'];
    expect(id, isNotNull);

    final getResponse = await get(Uri.parse('$host/api/clientes/$id'));
    expect(getResponse.statusCode, 200);

    final client = jsonDecode(getResponse.body);
    expect(client['nombre'], 'Cliente');
    expect(client['email'], 'cliente_$unique@test.com');
  });

  test('CRUD de ventas y detalle de venta', () async {
    final unique = DateTime.now().millisecondsSinceEpoch;
    final clienteResponse = await post(
      Uri.parse('$host/api/clientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': 'Venta',
        'apellido': 'Test',
        'telefono': '4444444',
        'email': 'venta_$unique@test.com',
      }),
    );

    final clienteId = jsonDecode(clienteResponse.body)['id'];

    final ventaResponse = await post(
      Uri.parse('$host/api/ventas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cliente_id': clienteId,
        'total': 150.0,
        'estado': 'pendiente',
      }),
    );

    expect(ventaResponse.statusCode, 201);
    final ventaId = jsonDecode(ventaResponse.body)['id'];

    final detalleResponse = await post(
      Uri.parse('$host/api/detalle-ventas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'venta_id': ventaId,
        'producto_id': 1,
        'cantidad': 2,
        'precio_unitario': 75.0,
      }),
    );

    expect(detalleResponse.statusCode, 201);

    final ventaDetalleResponse = await get(
      Uri.parse('$host/api/ventas/$ventaId/detalle'),
    );

    expect(ventaDetalleResponse.statusCode, 200);
    final payload = jsonDecode(ventaDetalleResponse.body);
    expect(payload['venta']['cliente_id'], clienteId);
    expect(payload['detalle'], isA<List>());
    expect(payload['detalle'][0]['cantidad'], 2);
  });

  test(
    'Venta transaccional crea cabecera y detalle en una sola operación',
    () async {
      final unique = DateTime.now().millisecondsSinceEpoch;

      final clienteResponse = await post(
        Uri.parse('$host/api/clientes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': 'Transaccional',
          'apellido': 'Cliente',
          'telefono': '7777777',
          'email': 'transaccional_$unique@test.com',
        }),
      );

      final clienteId = jsonDecode(clienteResponse.body)['id'];

      final response = await post(
        Uri.parse('$host/api/ventas/transaccional'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cliente_id': clienteId,
          'estado': 'pendiente',
          'items': [
            {'producto_id': 1, 'cantidad': 2},
            {'producto_id': 2, 'cantidad': 1},
          ],
        }),
      );

      expect(response.statusCode, 201);
      final body = jsonDecode(response.body);
      expect(body['venta']['cliente_id'], clienteId);
      expect(body['venta']['detalle'], isA<List>());
      expect(body['venta']['detalle'].length, 2);
    },
  );
}
