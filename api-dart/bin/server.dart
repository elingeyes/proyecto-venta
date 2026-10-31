import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:api_dart/database/database.dart';
import 'package:api_dart/routes/cliente_routes.dart';
import 'package:api_dart/routes/detalle_venta_routes.dart';
import 'package:api_dart/routes/producto_routes.dart';
import 'package:api_dart/routes/venta_routes.dart';

Future<void> main(List<String> args) async {
  final connection = await Database.connect();

  print('Conectado a MySQL.');

  final router = Router();

  router.get('/', (Request request) {
    return Response.ok('API Dart funcionando correctamente\n');
  });

  router.mount('/', productoRoutes(connection).call);
  router.mount('/', clienteRoutes(connection).call);
  router.mount('/', ventaRoutes(connection).call);
  router.mount('/', detalleVentaRoutes(connection).call);

  final ip = InternetAddress.anyIPv4;

  final handler = Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final server = await serve(handler, ip, port);

  print(
    'Servidor ejecutándose en http://${server.address.host}:${server.port}',
  );
  print('Servidor ejecutándose en http://localhost:${server.port}');
  print('API de productos: http://localhost:${server.port}/api/productos');
  print('API de clientes: http://localhost:${server.port}/api/clientes');
  print('API de ventas: http://localhost:${server.port}/api/ventas');
  print(
    'API de detalle de ventas: http://localhost:${server.port}/api/detalle-ventas',
  );
}

Middleware _corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
      };

      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      final response = await handler(request);
      return response.change(headers: {...response.headers, ...corsHeaders});
    };
  };
}
