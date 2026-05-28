import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  GoogleSignIn get _googleSignIn => GoogleSignIn(
    clientId: kIsWeb ? '433193562880-0lolvao40s0dgn51390fsndgaq921t8n.apps.googleusercontent.com' : null,
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
      debugPrint('Giriş hatası: ${e.message}');
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
      debugPrint('Google ile giriş hatası: $e');
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
      debugPrint('Kayıt hatası: ${e.message}');
      return null;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out hatası: $e');
    }
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  // Mevcut kullanıcıyı al
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
