import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/producto.dart';

class ProductoApi {
  ProductoApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static String get _defaultBaseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    // Edge corre en el mismo equipo que la API; Android usa el alias del host.
    return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }

  Future<List<Producto>> obtenerProductos() async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/api/productos'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('La API respondió con estado ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('La API no devolvió una lista de productos');
    }

    return decoded
        .map(
          (item) => Producto.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> crearProducto({
    required String nombre,
    required double precio,
  }) async {
    await _send(
      'POST',
      Uri.parse('$_baseUrl/api/productos'),
      body: {'nombre': nombre, 'precio': precio},
    );
  }

  Future<void> actualizarProducto({
    required int id,
    required String nombre,
    required double precio,
  }) async {
    await _send(
      'PUT',
      Uri.parse('$_baseUrl/api/productos/$id'),
      body: {'nombre': nombre, 'precio': precio},
    );
  }

  Future<void> eliminarProducto(int id) async {
    await _send('DELETE', Uri.parse('$_baseUrl/api/productos/$id'));
  }

  Future<void> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 10));
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = 'La API respondió con estado ${response.statusCode}';
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map && decoded['error'] != null) {
          detail = decoded['error'].toString();
        }
      } on FormatException {
        // Conserva el mensaje de estado si la API no devuelve JSON.
      }
      throw Exception(detail);
    }
  }

  void dispose() {
    _client.close();
  }
}
