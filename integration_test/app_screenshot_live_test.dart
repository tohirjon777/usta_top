
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:automaster/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitForUi(WidgetTester tester, {int ticks = 10}) async {
    for (int i = 0; i < ticks; i += 1) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> screenshotReady(String name) async {
    // The host script captures the iOS simulator while this marker is visible.
    // ignore: avoid_print
    print('SCREENSHOT_READY:$name');
    await Future<void>.delayed(const Duration(seconds: 8));
  }

  testWidgets('walks through app screens for screenshots', (
    WidgetTester tester,
  ) async {
    await app.main();
    await waitForUi(tester, ticks: 14);

    await screenshotReady('01_login');

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '+998 90 123 45 67',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Kirish'));
    await waitForUi(tester, ticks: 16);

    await screenshotReady('02_home');

    await tester.scrollUntilVisible(
      find.text('Turbo Usta Servis'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Turbo Usta Servis').first);
    await waitForUi(tester, ticks: 12);

    await screenshotReady('03_workshop_detail');

    await tester.binding.handlePopRoute();
    await waitForUi(tester, ticks: 10);

    await tester.tap(find.text('Buyurtmalar').last);
    await waitForUi(tester, ticks: 12);

    await screenshotReady('04_bookings');

    await tester.tap(find.text('Kabinet').last);
    await waitForUi(tester, ticks: 12);

    await screenshotReady('05_profile');
  });
}
