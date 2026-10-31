import 'package:mysql_client/mysql_client.dart';

class Database {
  static Future<MySQLConnection> connect() async {
    final connection = await MySQLConnection.createConnection(
      host: '127.0.0.1',
      port: 3306,
      userName: 'root',
      password: '',
      databaseName: 'api_dart',
    );

    await connection.connect();
    await ensureSchema(connection);

    return connection;
  }

  static Future<void> ensureSchema(MySQLConnection connection) async {
    final statements = [
      '''
      CREATE TABLE IF NOT EXISTS productos (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(150) NOT NULL,
        precio DECIMAL(10,2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS clientes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(150) NOT NULL,
        apellido VARCHAR(150),
        telefono VARCHAR(30),
        email VARCHAR(150),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS ventas (
        id INT AUTO_INCREMENT PRIMARY KEY,
        cliente_id INT NOT NULL,
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
        estado ENUM('pendiente', 'pagada', 'cancelada') NOT NULL DEFAULT 'pendiente',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        CONSTRAINT fk_ventas_clientes FOREIGN KEY (cliente_id) REFERENCES clientes(id)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS detalle_venta (
        id INT AUTO_INCREMENT PRIMARY KEY,
        venta_id INT NOT NULL,
        producto_id INT NOT NULL,
        cantidad INT NOT NULL,
        precio_unitario DECIMAL(10,2) NOT NULL,
        subtotal DECIMAL(10,2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        CONSTRAINT fk_detalle_venta_venta FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
        CONSTRAINT fk_detalle_venta_producto FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
      ''',
    ];

    for (final sql in statements) {
      await connection.execute(sql);
    }
  }
}
