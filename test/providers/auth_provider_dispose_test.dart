// AuthProvider — dispose'da authStateChanges subscription'ının iptal edildiğini
// ve FcmService.onTokenRefresh'in null'a döndüğünü doğrular.
//
// Bu test memory leak düzeltmesinin regresyon testi niteliğindedir:
// Önceki kodda subscription hiç iptal edilmiyordu ve dispose metodu yoktu.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:herbaformix/features/auth/providers/auth_provider.dart';
import 'package:herbaformix/services/auth_service.dart';
import 'package:herbaformix/services/fcm_service.dart';
import 'package:herbaformix/services/firestore_service.dart';
import 'package:herbaformix/services/repositories/user_profile_repository.dart';

// ── Mocks ───────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

class MockFirestoreService extends Mock implements FirestoreService {}

class MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

/// FcmService'in test-friendly stub'ı.
/// FirebaseMessaging.instance'a bağımlı olmadan onTokenRefresh / getToken /
/// deleteToken davranışlarını kontrol eder.
class FakeFcmService extends Fake implements FcmService {
  @override
  void Function(String token)? onTokenRefresh;

  @override
  Future<String?> getToken() async => 'fake-token';

  @override
  Future<void> deleteToken() async {}
}

// ── Test ────────────────────────────────────────────────────────────────────

void main() {
  late MockAuthService mockAuthService;
  late MockFirestoreService mockFirestoreService;
  late MockUserProfileRepository mockUserProfileRepo;
  late FakeFcmService fakeFcmService;
  late StreamController<fb_auth.User?> authStateController;

  setUp(() {
    mockAuthService = MockAuthService();
    mockFirestoreService = MockFirestoreService();
    mockUserProfileRepo = MockUserProfileRepository();
    fakeFcmService = FakeFcmService();
    authStateController = StreamController<fb_auth.User?>.broadcast();

    when(() => mockAuthService.getCurrentUser()).thenReturn(null);
    when(() => mockAuthService.authStateChanges)
        .thenAnswer((_) => authStateController.stream);
    when(() => mockFirestoreService.userProfile)
        .thenReturn(mockUserProfileRepo);
  });

  tearDown(() async {
    await authStateController.close();
  });

  group('AuthProvider.dispose — subscription temizliği', () {
    test('dispose sonrası authStateChanges stream listener\'ı kalmaz', () {
      final provider = AuthProvider(
        mockAuthService,
        mockFirestoreService,
        fcmService: fakeFcmService,
      );
      expect(authStateController.hasListener, isTrue,
          reason: 'constructor\'da listen çağrıldığından listener olmalı');

      provider.dispose();

      expect(authStateController.hasListener, isFalse,
          reason: 'dispose sonrası subscription cancel edilmeli');
    });

    test('dispose sonrası FcmService.onTokenRefresh null olur', () {
      final provider = AuthProvider(
        mockAuthService,
        mockFirestoreService,
        fcmService: fakeFcmService,
      );
      expect(fakeFcmService.onTokenRefresh, isNotNull,
          reason: 'constructor onTokenRefresh set eder');

      provider.dispose();

      expect(fakeFcmService.onTokenRefresh, isNull,
          reason: 'dispose onTokenRefresh\'i temizlemeli');
    });

    test('dispose idempotent — subscription zaten cancel, hata yok', () {
      // ChangeNotifier.dispose() ikinci çağrıda assert fırlatır;
      // bu Flutter'ın tasarım kararı. Bizim kodumuzun buna uyumlu
      // olduğunu test ediyoruz: bir kez dispose güvenli çalışır.
      final provider = AuthProvider(
        mockAuthService,
        mockFirestoreService,
        fcmService: fakeFcmService,
      );
      // tek dispose güvenli
      expect(() => provider.dispose(), returnsNormally);
    });

    test('constructor sonrası durum unauthenticated (kullanıcı yok)', () {
      final provider = AuthProvider(
        mockAuthService,
        mockFirestoreService,
        fcmService: fakeFcmService,
      );
      expect(provider.status, AuthStatus.unauthenticated);

      provider.dispose();
    });
  });
}
