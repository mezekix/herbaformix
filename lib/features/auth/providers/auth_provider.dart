import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart'; // Oluşturduğumuz AuthService

enum AuthStatus { uninitialized, authenticated, authenticating, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;

  AuthProvider(this._authService) {
    // Oturum durumunu dinle ve değişiklik olduğunda UI'ı güncelle
    _authService.authStateChanges.listen(_onAuthStateChanged);
    _user = _authService.getCurrentUser(); // Başlangıçta mevcut kullanıcıyı kontrol et
    _onAuthStateChanged(_user); // Durumu ayarla
  }

  User? get user => _user;
  AuthStatus get status => _status;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } else {
      _user = firebaseUser;
      // Burada kullanıcıya ait ek verileri Firestore'dan çekebilirsiniz
      _status = AuthStatus.authenticated;
    }
    print("AuthProvider: Durum değişti -> $_status, Kullanıcı: $_user");
    notifyListeners(); // UI'ı güncellemek için dinleyicileri haberdar et
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      if (userCredential?.user != null) {
        // _onAuthStateChanged zaten dinlendiği için durumu o güncelleyecek
        return true;
      }
      _status = AuthStatus.unauthenticated; // Başarısızsa
      notifyListeners();
      return false;
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
      final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
       if (userCredential?.user != null) {
        // _onAuthStateChanged zaten dinlendiği için durumu o güncelleyecek
        // Yeni kullanıcı için Firestore'da bir profil dokümanı oluşturabilirsiniz.
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
    // _onAuthStateChanged durumu güncelleyecek
  }
}