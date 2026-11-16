import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/features/attendance/controllers/attendance_controller.dart';
import 'package:vehicle_app/features/attendance/controllers/settlements_controller.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/models/monthly_settlement.dart';
import 'package:vehicle_app/features/attendance/widgets/arrears_alert_banner.dart';
import 'package:vehicle_app/features/attendance/widgets/salary_settlement_dialog.dart';
import 'package:vehicle_app/features/attendance/widgets/salary_settlement_tile.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

void main() {
  group('SalarySettlementTile & ArrearsAlertBanner Tests', () {
    testWidgets('SalarySettlementTile displays not recorded text initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementsControllerProvider.overrideWith(() => _FakeSettlementsController(
              const SettlementsState(),
            )),
          ],
          child: const MaterialApp(
            locale: Locale('ne'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: SalarySettlementTile(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('salary_settlement_tile')), findsOneWidget);
      expect(find.text('बैंक तलब भुक्तानी'), findsOneWidget);
      expect(find.text('बैंकमा प्राप्त तलब रकम दर्ता गर्नुहोस्'), findsOneWidget);
    });

    testWidgets('SalarySettlementTile displays fully settled when paid in full', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementsControllerProvider.overrideWith(() => _FakeSettlementsController(
              const SettlementsState(
                currentSettlement: MonthlySettlement(
                  bsYear: 2083,
                  bsMonthIndex: 6,
                  expectedAmount: 24000,
                  bankReceivedAmount: 24000,
                  settlementStatus: 'settled',
                ),
              ),
            )),
          ],
          child: const MaterialApp(
            locale: Locale('ne'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: SalarySettlementTile(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('बैंक तलब भुक्तानी'), findsOneWidget);
      expect(find.text('पूर्ण भुक्तानी भयो: रु. २४,०००'), findsOneWidget);
    });

    testWidgets('SalarySettlementTile displays pending deficit when partially paid', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementsControllerProvider.overrideWith(() => _FakeSettlementsController(
              const SettlementsState(
                currentSettlement: MonthlySettlement(
                  bsYear: 2083,
                  bsMonthIndex: 6,
                  expectedAmount: 24000,
                  bankReceivedAmount: 20000,
                  settlementStatus: 'partial',
                ),
              ),
            )),
          ],
          child: const MaterialApp(
            locale: Locale('ne'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: SalarySettlementTile(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('बाँकी बक्यौता: रु. ४,०००'), findsOneWidget);
    });

    testWidgets('ArrearsAlertBanner displays warning when previous month has unpaid dues', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider.overrideWith(() => _FakeAttendanceController(
              const AttendanceState(currentYear: 2083, currentMonthIndex: 7), // Mangsir
            )),
            settlementsControllerProvider.overrideWith(() => _FakeSettlementsController(
              const SettlementsState(
                previousSettlement: MonthlySettlement(
                  bsYear: 2083,
                  bsMonthIndex: 6, // Kartik
                  expectedAmount: 24000,
                  bankReceivedAmount: 20000, // Rs. 4000 deficit
                  settlementStatus: 'partial',
                ),
              ),
            )),
          ],
          child: const MaterialApp(
            locale: Locale('ne'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: ArrearsAlertBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('arrears_alert_banner')), findsOneWidget);
      expect(find.text('गत महिनाको बाँकी बक्यौता'), findsOneWidget);
      expect(find.text('रु. ४,०००'), findsOneWidget);
    });

    testWidgets('ArrearsAlertBanner is hidden when previous month has no dues', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider.overrideWith(() => _FakeAttendanceController(
              const AttendanceState(currentYear: 2083, currentMonthIndex: 7),
            )),
            settlementsControllerProvider.overrideWith(() => _FakeSettlementsController(
              const SettlementsState(
                previousSettlement: MonthlySettlement(
                  bsYear: 2083,
                  bsMonthIndex: 6,
                  expectedAmount: 24000,
                  bankReceivedAmount: 24000,
                  settlementStatus: 'settled',
                ),
              ),
            )),
          ],
          child: const MaterialApp(
            locale: Locale('ne'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: ArrearsAlertBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('arrears_alert_banner')), findsNothing);
    });

    testWidgets('SalarySettlementDialog provides BS / AD calendar toggle and synchronized date display', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider.overrideWith(() => _FakeAttendanceController(
              const AttendanceState(currentYear: 2083, currentMonthIndex: 6),
            )),
            settlementsControllerProvider.overrideWith(() => _FakeSettlementsController(
              const SettlementsState(),
            )),
          ],
          child: const MaterialApp(
            locale: Locale('ne'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: SalarySettlementDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for calendar toggles
      expect(find.byKey(const Key('toggle_calendar_bs')), findsOneWidget);
      expect(find.byKey(const Key('toggle_calendar_ad')), findsOneWidget);
      expect(find.byKey(const Key('settlement_date_picker_tile')), findsOneWidget);

      // Tap AD toggle
      await tester.tap(find.byKey(const Key('toggle_calendar_ad')));
      await tester.pumpAndSettle();

      // Tap BS toggle
      await tester.tap(find.byKey(const Key('toggle_calendar_bs')));
      await tester.pumpAndSettle();

      expect(find.text('मिति छान्नुहोस्'), findsOneWidget);
    });
  });
}

class _FakeSettlementsController extends SettlementsController {
  final SettlementsState _initialState;

  _FakeSettlementsController(this._initialState);

  @override
  SettlementsState build() => _initialState;

  @override
  Future<void> load({required int bsYear, required int bsMonthIndex}) async {}

  @override
  Future<void> saveSettlement({
    required int bsYear,
    required int bsMonthIndex,
    required int expectedAmount,
    required int bankReceivedAmount,
    required String? paymentDate,
    String? note,
  }) async {}
}

class _FakeAttendanceController extends AttendanceController {
  final AttendanceState _initialState;

  _FakeAttendanceController(this._initialState);

  @override
  AttendanceState build() => _initialState;
}
