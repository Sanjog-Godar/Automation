import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/features/auth/models/user_model.dart';
import 'package:vehicle_app/features/auth/repositories/auth_repository.dart';
import 'package:vehicle_app/features/auth/views/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.hasValidSession()).thenAnswer((_) async => false);
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders all required UI components matching Next.js web app', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Vehicle Attendance'), findsOneWidget);
      expect(find.text('Sign in to access your dashboard'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me for 30 days'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Ga 2 Pa 4066'), findsOneWidget);
    });

    testWidgets('Displays form validation errors when submitted empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap Sign In button without entering fields
      await tester.tap(find.text('Sign In'));
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

      await tester.pumpWidget(buildTestWidget());

      // Enter email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'your@email.com'),
        'driver@test.com',
      );

      // Enter password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        'secretpassword',
      );

      // Toggle remember me checkbox
      await tester.tap(find.text('Remember me for 30 days'));
      await tester.pump();

      // Submit
      await tester.tap(find.text('Sign In'));
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
