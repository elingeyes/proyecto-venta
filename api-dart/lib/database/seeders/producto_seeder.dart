import 'package:mysql_client/mysql_client.dart';

class ProductoSeeder {
  static Future<void> run(MySQLConnection connection) async {
    await connection.execute(
      'INSERT INTO productos (nombre, precio) VALUES (:nombre, :precio)',
      {'nombre': 'Arroz', 'precio': 12.50},
    );

    await connection.execute(
      'INSERT INTO productos (nombre, precio) VALUES (:nombre, :precio)',
      {'nombre': 'Azúcar', 'precio': 8.50},
    );

    print('Productos creados');
  }
}
