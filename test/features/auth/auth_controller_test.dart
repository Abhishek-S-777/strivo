import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strivo/core/sync/cloud_sync_repository.dart';
import 'package:strivo/features/auth/data/firebase_auth_repository.dart';
import 'package:strivo/features/auth/domain/auth_repository.dart';
import 'package:strivo/features/auth/presentation/providers/auth_providers.dart';

class FakeAuthRepository implements AuthRepository {
  AuthUser? user;
  String? remembered;
  AuthException? throwOnAction;
  final List<String> calls = [];

  @override
  AuthUser? get currentUser => user;

  @override
  String? get rememberedEmail => remembered;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(user);

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    if (throwOnAction != null) throw throwOnAction!;
    remembered = email;
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    calls.add('signUp:$email');
    if (throwOnAction != null) throw throwOnAction!;
    remembered = email;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    if (throwOnAction != null) throw throwOnAction!;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    remembered = null;
  }
}

class FakeCloudSyncRepository implements CloudSyncRepository {
  final List<String> calls = [];

  @override
  Future<({int sessions, int routines})> restoreFromCloud() async {
    calls.add('restore');
    return (sessions: 0, routines: 0);
  }

  @override
  Future<void> pushAllLocal() async => calls.add('push');

  @override
  Future<void> saveUserProfile({String? displayName, String? email}) async =>
      calls.add('saveProfile');
}

void main() {
  late FakeAuthRepository auth;
  late FakeCloudSyncRepository sync;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository();
    sync = FakeCloudSyncRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        cloudSyncRepositoryProvider.overrideWithValue(sync),
      ],
    );
    addTearDown(container.dispose);
  });

  AuthController controller() => container.read(authControllerProvider);

  group('AuthController', () {
    test('signUp backs up profile and local data on success', () async {
      final result = await controller().signUp('Alex', 'a@b.com', 'secret1');
      expect(result.success, isTrue);
      expect(auth.calls, contains('signUp:a@b.com'));
      expect(sync.calls, containsAll(<String>['saveProfile', 'push']));
    });

    test('signUp surfaces the auth error message on failure', () async {
      auth.throwOnAction = const AuthException('Email already in use.');
      final result = await controller().signUp('Alex', 'a@b.com', 'secret1');
      expect(result.success, isFalse);
      expect(result.error, 'Email already in use.');
      expect(sync.calls, isEmpty);
    });

    test(
      'signIn failure returns the message and skips cloud restore',
      () async {
        auth.throwOnAction = const AuthException(
          'Incorrect email or password.',
        );
        final result = await controller().signIn('a@b.com', 'wrong');
        expect(result.success, isFalse);
        expect(result.error, 'Incorrect email or password.');
        expect(sync.calls, isEmpty);
      },
    );

    test('sendPasswordReset maps success and failure', () async {
      expect((await controller().sendPasswordReset('a@b.com')).success, isTrue);
      auth.throwOnAction = const AuthException('Could not send reset email.');
      final failed = await controller().sendPasswordReset('a@b.com');
      expect(failed.success, isFalse);
      expect(failed.error, 'Could not send reset email.');
    });

    test('signOut delegates to the repository', () async {
      await controller().signOut();
      expect(auth.calls, contains('signOut'));
    });
  });
}
