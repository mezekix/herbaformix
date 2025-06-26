import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias ekledik
import 'package:flutter/foundation.dart';

import '../../../models/user_profile_model.dart'; // UserProfileModel'i import et
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart'; // FirestoreService'i import et

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService; // FirestoreService'i ekle

  fb_auth.User? _firebaseUser; // Firebase User objesi
  UserProfileModel? _userProfile; // Kendi UserProfileModel'imiz
  AuthStatus _status = AuthStatus.uninitialized;

  AuthProvider(this._authService, this._firestoreService) {
    // Constructor'a FirestoreService'i ekle
    _authService.authStateChanges.listen(_onAuthStateChanged);
    _firebaseUser = _authService.getCurrentUser();
    _onAuthStateChanged(_firebaseUser);
  }

  fb_auth.User? get firebaseUser => _firebaseUser;
  UserProfileModel? get userProfile => _userProfile; // Profil modelini dışa aç
  AuthStatus get status => _status;

  Future<void> _onAuthStateChanged(fb_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _firebaseUser = null;
      _userProfile = null; // Kullanıcı çıkış yapınca profili temizle
      _status = AuthStatus.unauthenticated;
    } else {
      _firebaseUser = firebaseUser;
      // Kullanıcı giriş yaptığında veya uygulama açıldığında profilini Firestore'dan çek
      _userProfile = await _firestoreService.getUserProfile(firebaseUser.uid);
      if (_userProfile == null) {
        // Eğer Firestore'da profil yoksa, yeni bir tane oluştur (opsiyonel, ilk girişte profil ekranına yönlendirilebilir)
        _userProfile = UserProfileModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? "N/A",
        );
        await _firestoreService.setUserProfile(_userProfile!);
        debugPrint(
          "Yeni kullanıcı için varsayılan profil oluşturuldu: ${firebaseUser.uid}",
        );
      }
      _status = AuthStatus.authenticated;
    }
    debugPrint(
      "AuthProvider: Durum değişti -> $_status, Firebase Kullanıcı: ${_firebaseUser?.uid}, Profil: ${_userProfile?.name}",
    );
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      // _onAuthStateChanged durumu ve profili güncelleyecek
      return userCredential?.user != null;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      if (userCredential?.user != null) {
        // Yeni kullanıcı için Firestore'da bir profil dokümanı oluştur
        final newUser = userCredential!.user!;
        _userProfile = UserProfileModel(
          id: newUser.uid,
          email: newUser.email ?? "E-posta yok",
        );
        await _firestoreService.setUserProfile(_userProfile!);
        debugPrint("Kayıt sonrası yeni profil oluşturuldu: ${newUser.uid}");
        // _onAuthStateChanged zaten dinlendiği için durumu o güncelleyecek,
        // ancak _userProfile'ı burada set etmek _onAuthStateChanged'den önce erişilebilir olmasını sağlar.
        // _status = AuthStatus.authenticated; // _onAuthStateChanged yapacak
        notifyListeners(); // Profilin hemen güncellenmesi için
        return true;
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    // _onAuthStateChanged durumu ve profili temizleyecek
  }

  // Profil güncelleme metodu (opsiyonel, direkt ProfileScreen'den de yapılabilir)
  Future<bool> updateUserProfile(UserProfileModel updatedProfile) async {
    if (_firebaseUser == null) return false;
    try {
      await _firestoreService.setUserProfile(updatedProfile);
      _userProfile = updatedProfile; // Lokal state'i de güncelle
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Profil güncelleme hatası (AuthProvider): $e");
      return false;
    }
  }
}
