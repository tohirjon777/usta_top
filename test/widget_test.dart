import 'package:flutter_test/flutter_test.dart';

import 'package:usta_top/main.dart';

void main() {
  testWidgets('shows app home and bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Usta Top'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
