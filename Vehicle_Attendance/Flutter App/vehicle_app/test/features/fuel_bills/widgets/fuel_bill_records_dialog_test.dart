import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/features/fuel_bills/controllers/fuel_bills_controller.dart';
import 'package:vehicle_app/features/fuel_bills/models/fuel_bill.dart';
import 'package:vehicle_app/features/fuel_bills/repositories/fuel_bills_repository.dart';
import 'package:vehicle_app/features/fuel_bills/widgets/fuel_bill_records_dialog.dart';
import 'package:vehicle_app/features/fuel_bills/widgets/fuel_bill_records_tile.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

class MockFuelBillsRepository extends Mock implements FuelBillsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFuelBillsRepository mockRepo;

  setUp(() {
    mockRepo = MockFuelBillsRepository();
    when(() => mockRepo.updateLastBillDate(any())).thenAnswer((inv) async => inv.positionalArguments[0] as String);
  });

  Widget buildTestTile({
    required List<FuelBill> bills,
    required String? lastBillDate,
    bool isDark = false,
    double width = 360,
    double textScale = 1.0,
    ProviderContainer? container,
  }) {
    when(() => mockRepo.fetchFuelBills()).thenAnswer((_) async => bills);
    when(() => mockRepo.fetchLastBillDate()).thenAnswer((_) async => lastBillDate);

    final scopeContainer = container ??
        ProviderContainer(
          overrides: [
            fuelBillsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

    // Eagerly trigger load
    scopeContainer.read(fuelBillsControllerProvider.notifier).load();

    return UncontrolledProviderScope(
      container: scopeContainer,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ne')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(brightness: isDark ? Brightness.dark : Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        FuelBillRecordsTile(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('FuelBillRecordsTile & FuelBillRecordsDialog Widget Tests', () {
    testWidgets('Tile displays "No fuel bill yet" when no date or bills exist', (tester) async {
      final container = ProviderContainer(
        overrides: [
          fuelBillsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: [Locale('en'), Locale('ne')],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: FuelBillRecordsTile()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('fuel_bill_records_tile')), findsOneWidget);
      expect(find.text('Fuel Bill Records'), findsOneWidget);
      expect(find.text('No fuel bill yet'), findsOneWidget);
    });

    testWidgets('Tile displays "Last bill ended: 2026-02-12" when bill date exists', (tester) async {
      await tester.pumpWidget(
        buildTestTile(
          bills: [
            const FuelBill(
              id: 1,
              startDate: '2026-02-01',
              endDate: '2026-02-12',
              totalKm: 1076,
              expectedLiters: 143.47,
              actualLiters: 144,
            ),
          ],
          lastBillDate: '2026-02-12',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Last bill ended: 2026-02-12'), findsOneWidget);
    });

    testWidgets('Tapping tile opens modal dialog showing Last Fuel Bill End Date and bill rows', (tester) async {
      await tester.pumpWidget(
        buildTestTile(
          bills: [
            const FuelBill(
              id: 1,
              startDate: '2026-02-01',
              endDate: '2026-02-12',
              totalKm: 1076,
              expectedLiters: 143.47,
              actualLiters: 144,
            ),
          ],
          lastBillDate: '2026-02-12',
        ),
      );
      await tester.pumpAndSettle();

      // Tap tile to open dialog
      await tester.tap(find.byKey(const Key('fuel_bill_records_tile')));
      await tester.pumpAndSettle();

      // Verify dialog contents
      expect(find.byType(FuelBillRecordsDialog), findsOneWidget);
      expect(find.text('Last Fuel Bill End Date'), findsOneWidget);
      expect(find.text('02/12/2026'), findsOneWidget);
      expect(find.byKey(const Key('dialog_generate_fuel_bill_button')), findsOneWidget);
      expect(find.text('2026-02-01 → 2026-02-12'), findsOneWidget);
      expect(find.textContaining('1,076 km'), findsOneWidget);
      expect(find.textContaining('143.47 L'), findsOneWidget);
      expect(find.textContaining('144 L'), findsOneWidget);

      // Tap Close button
      await tester.tap(find.byKey(const Key('fuel_bill_dialog_close')));
      await tester.pumpAndSettle();
      expect(find.byType(FuelBillRecordsDialog), findsNothing);
    });

    testWidgets('Dialog shows empty state message when bills list is empty', (tester) async {
      await tester.pumpWidget(buildTestTile(bills: [], lastBillDate: null));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fuel_bill_records_tile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fuel_bills_empty_state')), findsOneWidget);
      expect(find.textContaining('No fuel bill records found'), findsOneWidget);
    });

    testWidgets('Editing date in dialog immediately updates tile subtitle on dashboard', (tester) async {
      await tester.pumpWidget(
        buildTestTile(
          bills: [],
          lastBillDate: '2026-02-12',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Last bill ended: 2026-02-12'), findsOneWidget);

      // Open dialog
      await tester.tap(find.byKey(const Key('fuel_bill_records_tile')));
      await tester.pumpAndSettle();

      // Tap Edit Date button
      await tester.tap(find.byKey(const Key('fuel_bill_dialog_edit_date_btn')));
      await tester.pumpAndSettle();

      // Save new date
      await tester.tap(find.byKey(const Key('fuel_bill_dialog_save_date_btn')));
      await tester.pumpAndSettle();

      // Close dialog
      await tester.tap(find.byKey(const Key('fuel_bill_dialog_close')));
      await tester.pumpAndSettle();

      expect(find.text('Last bill ended: 2026-02-12'), findsOneWidget);
      verify(() => mockRepo.updateLastBillDate(any())).called(1);
    });

    testWidgets('Zero RenderFlex overflow on narrow 320dp width and textScale 1.2', (tester) async {
      await tester.pumpWidget(
        buildTestTile(
          bills: [
            const FuelBill(
              id: 1,
              startDate: '2026-02-01',
              endDate: '2026-02-12',
              totalKm: 1076,
              expectedLiters: 143.47,
              actualLiters: 144,
            ),
          ],
          lastBillDate: '2026-02-12',
          width: 320,
          textScale: 1.2,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Open dialog at 320dp, textScale 1.2
      await tester.tap(find.byKey(const Key('fuel_bill_records_tile')));
      await tester.pumpAndSettle();

      expect(find.byType(FuelBillRecordsDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
