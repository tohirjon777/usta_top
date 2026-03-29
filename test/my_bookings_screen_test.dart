import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:usta_top/core/localization/app_language.dart';
import 'package:usta_top/core/localization/app_localizations.dart';
import 'package:usta_top/models/booking_item.dart';
import 'package:usta_top/providers/booking_provider.dart';
import 'package:usta_top/screens/my_bookings_screen.dart';

void main() {
  Widget buildTestApp(List<BookingItem> bookings) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(seed: bookings),
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
        home: const Scaffold(body: MyBookingsScreen()),
      ),
    );
  }

  BookingItem buildCompletedBooking({
    String reviewId = '',
  }) {
    return BookingItem(
      id: 'b-1',
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
      status: BookingStatus.completed,
      completedAt: DateTime(2026, 3, 24, 11, 0),
      reviewId: reviewId,
      reviewSubmittedAt:
          reviewId.isEmpty ? null : DateTime(2026, 3, 24, 11, 10),
    );
  }

  BookingItem buildAcceptedBooking() {
    return BookingItem(
      id: 'b-2',
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
      status: BookingStatus.accepted,
      acceptedAt: DateTime(2026, 3, 24, 9, 30),
    );
  }

  BookingItem buildRescheduledBooking() {
    return BookingItem(
      id: 'b-3',
      workshopId: 'w-1',
      salonName: 'Turbo Usta Servis',
      masterName: 'Aziz Usta',
      serviceId: 'srv-1',
      serviceName: 'Kompyuter diagnostika',
      vehicleModel: 'Chevrolet Cobalt',
      vehicleTypeId: 'sedan',
      dateTime: DateTime(2026, 3, 24, 12, 0),
      basePrice: 120,
      price: 120,
      status: BookingStatus.rescheduled,
      previousDateTime: DateTime(2026, 3, 24, 10, 0),
      rescheduledAt: DateTime(2026, 3, 23, 18, 0),
      rescheduledByRole: 'owner_panel',
    );
  }

  testWidgets('completed booking without review shows write review CTA',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(<BookingItem>[buildCompletedBooking()]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sharh yozish'), findsOneWidget);
    expect(find.text('Sharhingiz yuborilgan'), findsNothing);
  });

  testWidgets('completed booking with review shows submitted label',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(<BookingItem>[buildCompletedBooking(reviewId: 'rv-1')]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sharhingiz yuborilgan'), findsOneWidget);
    expect(find.text('Sharh yozish'), findsNothing);
  });

  testWidgets('accepted booking stays accepted for customer UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(<BookingItem>[buildAcceptedBooking()]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Qabul qilindi'), findsOneWidget);
    expect(find.textContaining('Qabul qilingan vaqt:'), findsOneWidget);
    expect(find.text('Yakunlangan'), findsNothing);
    expect(find.text('Sharh yozish'), findsNothing);
    expect(find.text('Sharhingiz yuborilgan'), findsNothing);
  });

  testWidgets('rescheduled booking shows previous time and stays cancelable',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(<BookingItem>[buildRescheduledBooking()]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ko‘chirildi'), findsOneWidget);
    expect(find.textContaining('Oldingi vaqt:'), findsOneWidget);
    expect(find.text('Yangi vaqtni qabul qilish'), findsOneWidget);
    expect(find.text('Buyurtmani bekor qilish'), findsOneWidget);
    expect(find.text('Sharh yozish'), findsNothing);
  });
}
