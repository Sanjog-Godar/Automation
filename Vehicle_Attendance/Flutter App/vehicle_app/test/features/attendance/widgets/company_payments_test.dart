import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/features/attendance/controllers/attendance_controller.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/widgets/company_payments_dialog.dart';
import 'package:vehicle_app/features/attendance/widgets/company_payments_tile.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

void main() {
  group('CompanyPaymentsTile & CompanyPaymentsDialog Tests', () {
    testWidgets('CompanyPaymentsTile displays empty state text when no payments recorded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider.overrideWith(() => _FakeAttendanceController(
              const AttendanceState(
                currentYear: 2083,
                currentMonthIndex: 6,
                logs: [
                  AttendanceLog(
                    logDate: '2026-11-10',
                    status: AttendanceStatus.present,
                    advanceAmount: 0,
                  ),
                ],
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
              body: CompanyPaymentsTile(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('company_payments_tile')), findsOneWidget);
      expect(find.text('कम्पनीबाट प्राप्त रकम'), findsOneWidget);
      expect(find.text('महिनाको बीचमा प्राप्त रकम दर्ता गर्नुहोस्'), findsOneWidget);
    });

    testWidgets('CompanyPaymentsTile displays total received when advance payments exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider.overrideWith(() => _FakeAttendanceController(
              const AttendanceState(
                currentYear: 2083,
                currentMonthIndex: 6,
                logs: [
                  AttendanceLog(
                    logDate: '2026-11-10',
                    status: AttendanceStatus.present,
                    advanceAmount: 6000,
                    advanceNote: 'Upaye tip Kushma',
                  ),
                ],
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
              body: CompanyPaymentsTile(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('कम्पनीबाट प्राप्त रकम'), findsOneWidget);
      expect(find.text('जम्मा प्राप्त: रु. ६,०००'), findsOneWidget);
    });

    testWidgets('Tapping CompanyPaymentsTile opens CompanyPaymentsDialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider.overrideWith(() => _FakeAttendanceController(
              const AttendanceState(
                currentYear: 2083,
                currentMonthIndex: 6,
                logs: [
                  AttendanceLog(
                    logDate: '2026-11-10',
                    status: AttendanceStatus.present,
                    advanceAmount: 6000,
                    advanceNote: 'कुश्मा टिपको पैसा',
                  ),
                ],
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
              body: CompanyPaymentsTile(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('company_payments_tile')));
      await tester.pumpAndSettle();

      expect(find.byType(CompanyPaymentsDialog), findsOneWidget);
      expect(find.text('यस महिना प्राप्त कुल रकम'), findsOneWidget);
      expect(find.text('+ रकम थप्नुहोस्'), findsOneWidget);
      expect(find.text('कुश्मा टिपको पैसा'), findsOneWidget);
    });
  });
}

class _FakeAttendanceController extends AttendanceController {
  final AttendanceState _initialState;

  _FakeAttendanceController(this._initialState);

  @override
  AttendanceState build() => _initialState;

  @override
  Future<void> updateAdvancePayment({
    required String logDate,
    required int amount,
    String? note,
  }) async {}
}
