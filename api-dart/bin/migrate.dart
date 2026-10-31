import 'dart:io';
import 'package:api_dart/database/database.dart';

Future<void> main() async {
  print('Conectando a la base de datos...');

  final connection = await Database.connect();

  try {
    print('Conexión establecida.');

    await connection.execute('''
      CREATE TABLE IF NOT EXISTS migrations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        migration VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    final migrationsDirectory = Directory('lib/database/migrations');

    final files =
        migrationsDirectory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.sql'))
            .toList();

    files.sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final migrationName = file.uri.pathSegments.last;

      final result = await connection.execute(
        'SELECT id FROM migrations WHERE migration = :migration',
        {'migration': migrationName},
      );

      if (result.rows.isNotEmpty) {
        print('$migrationName ya ejecutada');
        continue;
      }

      final sql = await file.readAsString();

      await connection.execute(sql);

      await connection.execute(
        'INSERT INTO migrations (migration) VALUES (:migration)',
        {'migration': migrationName},
      );

      print('$migrationName ejecutada');
    }

    print('\nMigraciones completadas.');
  } finally {
    await connection.close();
  }
}
