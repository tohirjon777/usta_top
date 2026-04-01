import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:usta_top/main.dart';
import 'package:usta_top/core/config/backend_config.dart';
import 'package:usta_top/core/storage/backend_endpoint_storage.dart';

void main() {
  testWidgets('shows app home and bottom navigation', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_access_token': 'test-token',
    });

    await tester.pumpWidget(
      MyApp(
        backendEndpointStorage: const BackendEndpointStorage(),
        initialBackendBaseUrl: BackendConfig.resolveBaseUrl(),
        backendBaseUrlLocked: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Usta Top'), findsOneWidget);
    expect(find.text('Asosiy'), findsAtLeastNWidgets(1));
    expect(find.text('Xarita'), findsAtLeastNWidgets(1));
    expect(find.text('Buyurtmalar'), findsAtLeastNWidgets(1));
    expect(find.text('Kabinet'), findsAtLeastNWidgets(1));
  });
}
