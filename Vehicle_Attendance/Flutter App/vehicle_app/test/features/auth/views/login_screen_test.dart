import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_app/core/l10n/locale_provider.dart';
import 'package:vehicle_app/core/network/cookie_manager_provider.dart';
import 'package:vehicle_app/features/auth/models/user_model.dart';
import 'package:vehicle_app/features/auth/repositories/auth_repository.dart';
import 'package:vehicle_app/features/auth/views/login_screen.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.hasValidSession()).thenAnswer((_) async => false);
  });

  Widget buildTestWidget({Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        cookieJarProvider.overrideWithValue(CookieJar()),
        localeProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ne')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders all required UI components in English', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Vehicle Attendance'), findsOneWidget);
      expect(find.text('Sign in to access your dashboard'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
      expect(find.text('Ga 2 Pa 4066'), findsOneWidget);
      // Language chip shows 'English' when active language is English (never 'नेपाली' or inverted)
      expect(find.text('English'), findsOneWidget);
      expect(find.text('नेपाली'), findsNothing);
      expect(find.text('EN'), findsNothing);
    });

    testWidgets('Renders properly localized in Nepali without English leakage', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('ne')));
      await tester.pumpAndSettle();

      expect(find.text('सवारी साधन उपस्थिति'), findsOneWidget);
      expect(find.text('ड्यासबोर्ड हेर्न लग-इन गर्नुहोस्'), findsOneWidget);
      expect(find.text('इमेल ठेगाना'), findsOneWidget);
      expect(find.text('पासवर्ड'), findsOneWidget);
      expect(find.text('मलाई सम्झनुहोस्'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'लग-इन गर्नुहोस्'), findsOneWidget);
      // Language chip shows 'नेपाली' when active language is Nepali (never 'EN' or inverted)
      expect(find.text('नेपाली'), findsOneWidget);
      expect(find.text('English'), findsNothing);
      expect(find.text('EN'), findsNothing);
    });

    testWidgets('Displays form validation errors when submitted empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Tap Sign in button without entering fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      verifyNever(() => mockAuthRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberMe: any(named: 'rememberMe'),
          ));
    });

    testWidgets('Submits credentials and triggers login flow', (tester) async {
      when(
        () => mockAuthRepository.login(
          email: 'driver@test.com',
          password: 'secretpassword',
          rememberMe: true,
        ),
      ).thenAnswer(
        (_) async => const UserModel(id: 'usr-1', email: 'driver@test.com'),
      );

      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Enter email
      await tester.enterText(
        find.byType(TextFormField).first,
        'driver@test.com',
      );

      // Enter password
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'secretpassword',
      );

      // Toggle remember me checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();

      verify(
        () => mockAuthRepository.login(
          email: 'driver@test.com',
          password: 'secretpassword',
          rememberMe: true,
        ),
      ).called(1);
    });
  });
}

class _FixedLocaleNotifier extends LocaleNotifier {
  final Locale _fixed;
  _FixedLocaleNotifier(this._fixed);

  @override
  Locale build() => _fixed;
}
