import 'package:flutter_test/flutter_test.dart';
import 'package:jagofarm_app/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JagoFarmApp());
    expect(find.text('JagoFarm'), findsWidgets);
  });
}
