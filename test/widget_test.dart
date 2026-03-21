import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:usta_top/main.dart';

void main() {
  testWidgets('shows app home and bottom navigation', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_access_token': 'test-token',
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Usta Top'), findsOneWidget);
    expect(find.text('Asosiy'), findsOneWidget);
    expect(find.text('Buyurtmalar'), findsOneWidget);
    expect(find.text('Kabinet'), findsOneWidget);
  });
}
