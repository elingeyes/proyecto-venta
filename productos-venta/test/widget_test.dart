import 'package:flutter_test/flutter_test.dart';

import 'package:untitled1/main.dart';

void main() {
  testWidgets('muestra el menú principal', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Panel de administración'), findsOneWidget);
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Administrar catálogo'), findsOneWidget);
  });
}
