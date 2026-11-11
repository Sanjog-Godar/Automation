import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/features/auth/controllers/auth_controller.dart';
import 'package:vehicle_app/features/auth/models/auth_state.dart';
import 'package:vehicle_app/features/auth/models/user_model.dart';
import 'package:vehicle_app/features/auth/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.getPersistedUser()).thenReturn(null);
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthController Tests', () {
    test('checkSession marks authenticated and restores persisted user', () async {
      when(() => mockAuthRepository.hasValidSession()).thenAnswer((_) async => true);
      when(() => mockAuthRepository.getPersistedUser())
          .thenReturn(const UserModel(id: 'usr-persisted', email: 'driver@persisted.com'));

      final container = createContainer();
      final controller = container.read(authControllerProvider.notifier);

      await controller.checkSession();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.id, 'usr-persisted');
      expect(state.user?.email, 'driver@persisted.com');
    });

    test('login updates state to authenticated on success', () async {
      when(() => mockAuthRepository.hasValidSession()).thenAnswer((_) async => false);
      when(
        () => mockAuthRepository.login(
          email: 'driver@test.com',
          password: 'secret',
          rememberMe: true,
        ),
      ).thenAnswer(
        (_) async => const UserModel(id: 'usr-1', email: 'driver@test.com'),
      );

      final container = createContainer();
      final controller = container.read(authControllerProvider.notifier);
      await controller.checkSession();

      final success = await controller.login(
        email: 'driver@test.com',
        password: 'secret',
        rememberMe: true,
      );

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.email, 'driver@test.com');
      expect(state.errorMessage, null);
    });

    test('login updates state to error when repository throws AuthException', () async {
      when(() => mockAuthRepository.hasValidSession()).thenAnswer((_) async => false);
      when(
        () => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          rememberMe: any(named: 'rememberMe'),
        ),
      ).thenThrow(const AuthException('Invalid email or password', 401));

      final container = createContainer();
      final controller = container.read(authControllerProvider.notifier);
      await controller.checkSession();

      final success = await controller.login(
        email: 'bad@test.com',
        password: 'wrong',
        rememberMe: false,
      );

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Invalid email or password');
    });

    test('logout clears user state and transitions to unauthenticated', () async {
      when(() => mockAuthRepository.hasValidSession()).thenAnswer((_) async => false);
      when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

      final container = createContainer();
      final controller = container.read(authControllerProvider.notifier);

      await controller.logout();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, null);
    });
  });
}
