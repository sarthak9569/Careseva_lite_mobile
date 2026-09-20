import 'package:flutter_test/flutter_test.dart';
import 'package:careseva_mobile_app/main.dart';

void main() {
  testWidgets('Mobile App loads cleanly test', (WidgetTester tester) async {
    await tester.pumpWidget(const CareSevaMobileApp());
    expect(find.textContaining('CareSeva'), findsWidgets);
  });
}
