import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:automaster/core/config/backend_config.dart';
import 'package:automaster/core/storage/backend_endpoint_storage.dart';
import 'package:automaster/main.dart';

void main() {
  Future<void> waitForUi(WidgetTester tester) async {
    for (int i = 0; i < 8; i += 1) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<GlobalKey> pumpApp(WidgetTester tester) async {
    // Temporary progress logs make it easier to diagnose screenshot captures.
    // This file is removed after the screenshots are generated.
    // ignore: avoid_print
    print('pumpApp:start');
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final GlobalKey screenshotKey = GlobalKey();
    await tester.pumpWidget(
      SizedBox(
        width: 390,
        height: 844,
        child: RepaintBoundary(
          key: screenshotKey,
          child: MyApp(
            backendEndpointStorage: const BackendEndpointStorage(),
            startupErrorMessage: null,
            initialBackendBaseUrl: BackendConfig.resolveBaseUrl(),
            backendBaseUrlLocked: false,
          ),
        ),
      ),
    );
    // ignore: avoid_print
    print('pumpApp:widget pumped');
    await waitForUi(tester);
    // ignore: avoid_print
    print('pumpApp:ui ready');
    return screenshotKey;
  }

  Future<void> capture(
    WidgetTester tester,
    GlobalKey screenshotKey,
    String fileName,
  ) async {
    // ignore: avoid_print
    print('capture:start:$fileName');
    await tester.pump(const Duration(milliseconds: 250));
    // ignore: avoid_print
    print('capture:pumped:$fileName');
    await expectLater(
      find.byKey(screenshotKey),
      matchesGoldenFile('../generated_screenshots/automaster/$fileName'),
    );
    // ignore: avoid_print
    print('capture:done:$fileName');
  }

  testWidgets('captures app screenshots', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GlobalKey screenshotKey = await pumpApp(tester);

    await capture(tester, screenshotKey, '01_login.png');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 250));

    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_access_token': 'test-token',
    });
    screenshotKey = await pumpApp(tester);

    await capture(tester, screenshotKey, '02_home.png');

    await tester.scrollUntilVisible(
      find.text('Turbo Usta Servis'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Turbo Usta Servis').first);
    await waitForUi(tester);
    await capture(tester, screenshotKey, '03_workshop_detail.png');

    await tester.binding.handlePopRoute();
    await waitForUi(tester);

    await tester.tap(find.text('Buyurtmalar').last);
    await waitForUi(tester);
    await capture(tester, screenshotKey, '04_bookings.png');

    await tester.tap(find.text('Kabinet').last);
    await waitForUi(tester);
    await capture(tester, screenshotKey, '05_profile.png');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 250));
  });
}
