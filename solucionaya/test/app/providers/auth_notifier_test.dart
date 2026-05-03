import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solucionaya/app/providers/auth_provider.dart';
import 'package:solucionaya/data/models/user_model.dart';
import 'package:solucionaya/data/repositories/auth_repository.dart';
import 'package:solucionaya/data/repositories/user_repository.dart';

void main() {
  group('AuthNotifier', () {
    test('guarda verificationId cuando envia OTP', () async {
      final authRepo = _FakeAuthRepository()..nextVerificationId = 'verif-123';
      final notifier = AuthNotifier(
        authRepo: authRepo,
        userRepo: _FakeUserRepository(),
      );

      final success = await notifier.sendOtp(phone: '3001234567');

      expect(success, isTrue);
      expect(notifier.phoneVerificationId, 'verif-123');
      expect(notifier.error, isNull);
    });

    test('crea perfil cliente al registrar con email', () async {
      final authRepo = _FakeAuthRepository();
      final userRepo = _FakeUserRepository();
      final notifier = AuthNotifier(authRepo: authRepo, userRepo: userRepo);

      final success = await notifier.registerClientWithEmail(
        email: 'ana@test.com',
        password: '12345678',
        displayName: 'Ana Gomez',
        phone: '3001234567',
        city: 'Bucaramanga',
      );

      expect(success, isTrue);
      expect(userRepo.createdUsers, hasLength(1));
      expect(userRepo.createdUsers.single.email, 'ana@test.com');
      expect(userRepo.createdUsers.single.role, UserRole.client);
    });

    test('elimina perfil y cuenta actual', () async {
      final authRepo = _FakeAuthRepository();
      final userRepo = _FakeUserRepository();
      final notifier = AuthNotifier(authRepo: authRepo, userRepo: userRepo);

      final success = await notifier.deleteCurrentAccount();

      expect(success, isTrue);
      expect(userRepo.deletedUserIds, ['test-uid']);
      expect(authRepo.deleteCalled, isTrue);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  String nextVerificationId = 'default-verification-id';
  bool deleteCalled = false;

  @override
  Stream<User?> get authStateChanges => const Stream<User?>.empty();

  @override
  User? get currentUser => _FakeUser();

  @override
  Future<void> deleteAccount() async {
    deleteCalled = true;
  }

  @override
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return _FakeUserCredential(_FakeUser());
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<String> signInWithPhone(String phone) async => nextVerificationId;

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _FakeUserCredential(_FakeUser());
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserCredential> verifyOtp(String verificationId, String otp) async {
    return _FakeUserCredential(_FakeUser());
  }
}

class _FakeUserRepository implements UserRepository {
  final List<UserModel> createdUsers = [];
  final List<String> deletedUserIds = [];

  @override
  Future<void> createUser(UserModel user) async {
    createdUsers.add(user);
  }

  @override
  Future<void> deleteUser(String uid) async {
    deletedUserIds.add(uid);
  }

  @override
  Future<UserModel?> getUser(String uid) async => null;

  @override
  Future<void> updateFcmToken(String uid, String token) async {}

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {}

  @override
  Stream<UserModel?> watchUser(String uid) => const Stream<UserModel?>.empty();
}

class _FakeUserCredential extends Fake implements UserCredential {
  _FakeUserCredential(this._user);

  final User _user;

  @override
  User? get user => _user;
}

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'test-uid';
}
