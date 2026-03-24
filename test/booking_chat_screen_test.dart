import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:usta_top/core/localization/app_language.dart';
import 'package:usta_top/core/localization/app_localizations.dart';
import 'package:usta_top/models/booking_item.dart';
import 'package:usta_top/providers/booking_provider.dart';
import 'package:usta_top/screens/booking_chat_screen.dart';

void main() {
  final BookingItem booking = BookingItem(
    id: 'b-chat-1',
    workshopId: 'w-1',
    salonName: 'Turbo Usta Servis',
    masterName: 'Aziz Usta',
    serviceId: 'srv-1',
    serviceName: 'Kompyuter diagnostika',
    vehicleModel: 'Chevrolet Cobalt',
    vehicleTypeId: 'sedan',
    dateTime: DateTime(2026, 3, 24, 10, 0),
    basePrice: 120,
    price: 120,
  );

  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(seed: <BookingItem>[booking]),
        ),
      ],
      child: MaterialApp(
        locale: AppLanguage.uzbek.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => BookingChatScreen(
                          booking: booking,
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('booking chat screen opens without semantics assertion', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(BookingChatScreen), findsOneWidget);
    expect(find.text('Turbo Usta Servis'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
