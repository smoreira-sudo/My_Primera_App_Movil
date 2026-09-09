import 'package:flutter_test/flutter_test.dart';
import 'package:exclusive_barber/main.dart';

void main() {
  testWidgets('Carga inicial de la app Exclusive Barber', (WidgetTester tester) async {
    // Renderiza la aplicación principal de la barbería
    await tester.pumpWidget(const ExclusiveBarberApp());
  });
}
