import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cliente.dart';
import '../models/producto.dart';

class VentaApi {
  VentaApi({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<List<Cliente>> obtenerClientes() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/clientes'),
      headers: {'Accept': 'application/json'},
    );
    _validar(response);
    final data = jsonDecode(response.body);
    if (data is! List) {
      throw const FormatException('La API no devolvió una lista de clientes');
    }
    return data
        .map((item) => Cliente.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> crearVentaTransaccional({
    required int clienteId,
    required List<DetalleVentaRequest> items,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/ventas/transaccional'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cliente_id': clienteId,
        'estado': 'pendiente',
        'items': items.map((item) => item.toJson()).toList(),
      }),
    );
    _validar(response);
  }

  void _validar(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'La API respondió con estado ${response.statusCode}';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['error'] != null) {
        message = data['error'].toString();
      }
    } on FormatException {
      // Conserva el mensaje de estado para respuestas no JSON.
    }
    throw Exception(message);
  }

  void dispose() => _client.close();
}

class DetalleVentaRequest {
  const DetalleVentaRequest({required this.productoId, required this.cantidad});

  final int productoId;
  final int cantidad;

  Map<String, dynamic> toJson() => {
    'producto_id': productoId,
    'cantidad': cantidad,
  };
}

class DetalleCarrito {
  const DetalleCarrito({required this.producto, required this.cantidad});

  final Producto producto;
  final int cantidad;

  double get subtotal => producto.precio * cantidad;
}
