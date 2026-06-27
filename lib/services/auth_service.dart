import 'package:firebase_auth/firebase_auth.dart';
import 'package:herbaformix/core/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Google OAuth Web Client ID.
  ///
  /// Derleme zamanında `--dart-define=GOOGLE_WEB_CLIENT_ID=...` ile geçirilir.
  /// OAuth client ID'leri tasarım gereği "public" olsa da kaynağa gömmek
  /// rotasyonu zorlaştırır ve ortamlar arası geçişi engeller (dev / prod).
  ///
  /// Örnek:
  ///   flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=xxxxx.apps.googleusercontent.com
  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  GoogleSignIn get _googleSignIn => GoogleSignIn(
    clientId: kIsWeb && _webClientId.isNotEmpty ? _webClientId : null,
  );

  // Kullanıcı oturum durumunu dinle
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // E-posta ve şifre ile giriş
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Hata yönetimi (örneğin, kullanıcıya göstermek için)
      AppLogger.error('Giriş hatası', tag: 'AuthService', error: e);
      return null;
    }
  }

  // Google ile giriş
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı iptal etti
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      AppLogger.error('Google ile giriş hatası', tag: 'AuthService', error: e);
      rethrow;
    }
  }

  // Anonim (Misafir) olarak giriş
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _firebaseAuth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Anonim giriş hatası', tag: 'AuthService', error: e);
      return null;
    }
  }

  /// Google sign-in akışını tetikler ve sadece [AuthCredential]'ı döner —
  /// signIn yapmaz. Reauth (örn. hesap silme öncesi kimlik doğrulama) için
  /// kullanılır. Kullanıcı seçimi iptal ederse `null` döner.
  Future<AuthCredential?> getGoogleAuthCredential() async {
    try {
      // Yeni bir hesap seçim ekranı için önce mevcut Google oturumunu kapat
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      return GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } catch (e) {
      AppLogger.error('getGoogleAuthCredential hatası', tag: 'AuthService', error: e);
      rethrow;
    }
  }

  // E-posta ve şifre ile kayıt
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Kayıt hatası', tag: 'AuthService', error: e);
      return null;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      AppLogger.error('Google Sign-Out hatası', tag: 'AuthService', error: e);
    }
  }

  /// Sadece Google oturumunu kapatır (Firebase oturumuna dokunmaz).
  Future<void> signOutGoogleOnly() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      AppLogger.error('Google Sign-Out hatası (signOutGoogleOnly)', tag: 'AuthService', error: e);
    }
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      AppLogger.error('Şifre sıfırlama hatası', tag: 'AuthService', error: e);
      rethrow;
    }
  }

  // Mevcut kullanıcıyı al
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
