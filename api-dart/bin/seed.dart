import 'package:api_dart/database/database.dart';
import 'package:api_dart/database/seeders/producto_seeder.dart';

Future<void> main() async {
  print('Iniciando seeders...');

  final connection = await Database.connect();

  try {
    await ProductoSeeder.run(connection);

    print('Seeders ejecutados correctamente.');
  } catch (e) {
    print('Error ejecutando seeders: $e');
  } finally {
    await connection.close();
  }
}
