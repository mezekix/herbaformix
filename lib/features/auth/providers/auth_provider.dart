import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias ekledik
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/user_profile_model.dart'; // UserProfileModel'i import et
import '../../../models/user_role.dart';
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
  String? _errorMessage; // Hata mesajlarını tutmak için
  bool _notifyScheduled = false;

  /// notifyListeners'ı güvenli bir şekilde erteler.
  ///
  /// AuthProvider, MultiProvider altında MaterialApp'ın **üstünde** yer alır.
  /// Doğrudan notifyListeners çağrıldığında, MaterialApp'ın alt ağacındaki
  /// bağımlı widget'lar farklı build scope'unda dirty olarak işaretlenir.
  /// Eğer aynı frame'de MediaQuery güncellemesi (klavye kapanması vb.)
  /// gerçekleşirse, iki farklı scope'taki rebuild'ler çakışır ve
  /// `_dependents.isEmpty` assertion hatası fırlatılır.
  ///
  /// Bu override, bildirimleri [addPostFrameCallback] ile mevcut frame
  /// sonrasına erteler ve birden fazla hızlı çağrıyı tek bir bildirime
  /// birleştirir (debounce).
  @override
  void notifyListeners() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      super.notifyListeners();
    });
  }

  AuthProvider(this._authService, this._firestoreService) {
    _firebaseUser = _authService.getCurrentUser();
    if (_firebaseUser != null) {
      _status = AuthStatus.authenticating;
      // microtask kullanmıyoruz — authStateChanges stream'i zaten
      // ilk event olarak mevcut kullanıcıyı verecek.
      // İkisini birden çağırmak yarış durumuna ve çift Firestore
      // çağrısına yol açıyordu.
    } else {
      _status = AuthStatus.unauthenticated;
    }
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  fb_auth.User? get firebaseUser => _firebaseUser;
  UserProfileModel? get userProfile => _userProfile; // Profil modelini dışa aç
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage; // Hata mesajını dışa aç

  bool _isCustomerModeActive = false;
  bool get isCustomerModeActive => _isCustomerModeActive;

  void toggleCustomerMode() {
    _isCustomerModeActive = !_isCustomerModeActive;
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(fb_auth.User? firebaseUser) async {
    try {
      if (firebaseUser == null) {
        if (_firebaseUser == null && _status == AuthStatus.unauthenticated) {
          return;
        }
        _firebaseUser = null;
        _userProfile = null; // Kullanıcı çıkış yapınca profili temizle
        _status = AuthStatus.unauthenticated;
      } else {
        if (_firebaseUser?.uid == firebaseUser.uid &&
            _status == AuthStatus.authenticated &&
            _userProfile != null) {
          return;
        }
        _firebaseUser = firebaseUser;
        _status = AuthStatus.authenticating; // Profil çekilirken de bu durumda kalabiliriz
        notifyListeners();

        // Kullanıcı giriş yaptığında veya uygulama açıldığında profilini Firestore'dan çek
        final profile = await _firestoreService.getUserProfile(firebaseUser.uid);
        if (profile != null) {
          _userProfile = profile;
        } else if (_userProfile?.id != firebaseUser.uid) {
          _userProfile = null;
          debugPrint("Firestore'da profil bulunamadı: ${firebaseUser.uid}");
          // Profil yoksa null kalacak, signUp veya Login sonrası işlemler halledebilir
        }
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      debugPrint("AuthProvider Error (_onAuthStateChanged): $e");
      _status = AuthStatus.unauthenticated;
      _errorMessage = "Bir hata oluştu: $e";
    } finally {
      debugPrint(
        "AuthProvider: Durum değişti -> $_status, Firebase Kullanıcı: ${_firebaseUser?.uid}, Profil: ${_userProfile?.name}",
      );
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (userCredential == null) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = "Giriş başarısız. Lütfen bilgilerinizi kontrol edin.";
        notifyListeners();
        return false;
      }
      
      // _onAuthStateChanged durumu ve profili güncelleyecek
      return true;
    } catch (e) {
      debugPrint("AuthProvider Error (signIn): $e");
      _status = AuthStatus.unauthenticated;
      _errorMessage = "Giriş sırasında bir hata oluştu: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle({UserRole role = UserRole.customer, String? inviteCode}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      String? distributorId;

      // Davet kodunu doğrula (eğer varsa)
      if (inviteCode != null && inviteCode.trim().isNotEmpty) {
        final inviteCodeModel = await _firestoreService.validateInviteCode(inviteCode.trim());
        if (inviteCodeModel == null) {
          _status = AuthStatus.unauthenticated;
          _errorMessage = 'Geçersiz davet kodu.';
          notifyListeners();
          return false;
        }
        distributorId = inviteCodeModel.distributorId;
      }

      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential == null) {
        _status = AuthStatus.unauthenticated;
        // User cancelled login or it failed without throwing
        notifyListeners();
        return false;
      }
      
      // Check if user is newly registered by checking if they have a profile
      if (userCredential.user != null) {
        final existingProfile = await _firestoreService.getUserProfile(userCredential.user!.uid);
        if (existingProfile == null) {
          // If no profile exists, create one with the specified role (or customer by default)
          final newProfile = UserProfileModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? "E-posta yok",
            name: userCredential.user!.displayName ?? "",
            role: role,
            assignedDistributorId: distributorId,
          );
          
          if (inviteCode != null && inviteCode.trim().isNotEmpty && distributorId != null) {
            // Atomik batch yazma: profil oluşturma + davet kodu güncelleme
            final inviteCodeModel = await _firestoreService.validateInviteCode(inviteCode.trim());
            if (inviteCodeModel != null) {
              await _firestoreService.signUpWithInviteCodeBatch(
                userProfile: newProfile,
                inviteCode: inviteCodeModel,
                newUserId: userCredential.user!.uid,
              );
            } else {
              await _firestoreService.setUserProfile(newProfile);
            }
          } else {
            await _firestoreService.setUserProfile(newProfile);
          }
          _userProfile = newProfile;
          notifyListeners();
          debugPrint("Google ile giriş sonrası yeni profil oluşturuldu: ${userCredential.user!.uid}");
        } else {
          _userProfile = existingProfile;
          debugPrint("Google ile giriş sonrası mevcut profil yüklendi: ${userCredential.user!.uid}");
        }
        notifyListeners();
      }

      // _onAuthStateChanged durumu ve profili güncelleyecek
      return true;
    } catch (e) {
      debugPrint("AuthProvider Error (signInWithGoogle): $e");
      _status = AuthStatus.unauthenticated;
      _errorMessage = "Google ile giriş sırasında bir hata oluştu: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, UserRole role) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      if (userCredential?.user != null) {
        // Yeni kullanıcı için Firestore'da bir profil dokümanı oluştur
        final newUser = userCredential!.user!;
        final newProfile = UserProfileModel(
          id: newUser.uid,
          email: newUser.email ?? "E-posta yok",
          role: role,
        );
        await _firestoreService.setUserProfile(newProfile);
        _userProfile = newProfile;
        debugPrint("Kayıt sonrası yeni profil oluşturuldu: ${newUser.uid}");
        notifyListeners();
        // _onAuthStateChanged zaten dinlendiği için durumu o güncelleyecek
        return true;
      }
      _status = AuthStatus.unauthenticated;
      _errorMessage = "Kayıt başarısız. E-posta adresi kullanımda olabilir.";
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("AuthProvider Error (signUp): $e");
      _status = AuthStatus.unauthenticated;
      _errorMessage = "Kayıt sırasında bir hata oluştu: $e";
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

  /// Firestore'dan kullanıcı profilini yeniden çeker ve lokal state'i günceller.
  ///
  /// Davet kodu kullanımı gibi atomik batch işlemlerinden sonra
  /// lokal profil state'inin güncel kalmasını sağlar.
  Future<void> refreshProfile() async {
    if (_firebaseUser == null) return;
    try {
      _userProfile = await _firestoreService.getUserProfile(_firebaseUser!.uid);
      notifyListeners();
    } catch (e) {
      debugPrint("Profil yenileme hatası (AuthProvider): $e");
    }
  }

  /// Mevcut şifreyi doğrulayarak yeni şifreyle değiştirir.
  ///
  /// Önce `reauthenticateWithCredential` ile kimlik doğrulaması yapar,
  /// ardından `updatePassword` ile şifreyi günceller.
  /// Hata durumunda `FirebaseAuthException.code` değerine göre anlamlı mesaj fırlatır.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_firebaseUser == null) {
      throw Exception('Kullanıcı oturumu bulunamadı.');
    }

    try {
      final email = _firebaseUser!.email;
      if (email == null) {
        throw Exception('Kullanıcı e-posta adresi bulunamadı.');
      }

      // Mevcut şifreyle yeniden kimlik doğrulama
      final credential = fb_auth.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await _firebaseUser!.reauthenticateWithCredential(credential);

      // Yeni şifreyi güncelle
      await _firebaseUser!.updatePassword(newPassword);
    } on fb_auth.FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'wrong-password' => 'Mevcut şifreniz hatalı.',
        'requires-recent-login' =>
          'Güvenlik nedeniyle lütfen tekrar giriş yapın.',
        'weak-password' => 'Şifre en az 6 karakter olmalıdır.',
        _ => 'Şifre değiştirilemedi: ${e.message}',
      };
      throw Exception(message);
    }
  }

  /// Profil fotoğrafını cihazın kalıcı dizinine kaydeder ve local path'i döner.
  Future<String?> uploadProfilePhoto(File imageFile) async {
    if (_firebaseUser == null) return null;
    try {
      final uid = _firebaseUser!.uid;
      final appDir = await getApplicationDocumentsDirectory();
      final destPath = '${appDir.path}/profile_$uid.jpg';
      final destFile = await imageFile.copy(destPath);
      debugPrint('Profil fotoğrafı local kaydedildi: ${destFile.path}');

      // Fotoğraf güncelleme tarihini profile kaydet (immutable copyWith)
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          profilePhotoUpdatedAt: DateTime.now(),
        );
      }

      return destFile.path;
    } catch (e) {
      debugPrint('Profil fotoğrafı kaydetme hatası: $e');
      return null;
    }
  }

  /// Davet koduyla yeni kullanıcı kaydı yapar.
  ///
  /// - `inviteCode` doluysa `FirestoreService.validateInviteCode` ile doğrular.
  /// - Geçerliyse `FirestoreService.signUpWithInviteCodeBatch` ile atomik kayıt yapar.
  /// - `inviteCode` boşsa normal `signUp` akışını kullanır.
  /// - Hata durumunda `_errorMessage` set eder ve `false` döner.
  Future<bool> signUpWithInviteCode({
    required String email,
    required String password,
    required UserRole role,
    String? inviteCode,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      // Davet kodu yoksa normal kayıt akışı
      if (inviteCode == null || inviteCode.trim().isEmpty) {
        return await signUp(email, password, role);
      }

      // Davet kodunu doğrula
      final inviteCodeModel = await _firestoreService.validateInviteCode(
        inviteCode.trim(),
      );

      if (inviteCodeModel == null) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Geçersiz davet kodu.';
        notifyListeners();
        return false;
      }

      // Firebase Auth ile kullanıcı oluştur
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential?.user == null) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Kayıt başarısız. E-posta adresi kullanımda olabilir.';
        notifyListeners();
        return false;
      }

      final newUser = userCredential!.user!;

      // Kullanıcı profilini davet kodu bilgileriyle oluştur
      final newProfile = UserProfileModel(
        id: newUser.uid,
        email: newUser.email ?? email,
        role: role,
        assignedDistributorId: inviteCodeModel.distributorId,
      );

      // Atomik batch yazma: profil oluşturma + davet kodu güncelleme
      await _firestoreService.signUpWithInviteCodeBatch(
        userProfile: newProfile,
        inviteCode: inviteCodeModel,
        newUserId: newUser.uid,
      );

      _userProfile = newProfile;
      debugPrint(
        'Davet koduyla kayıt başarılı: ${newUser.uid}, distribütör: ${inviteCodeModel.distributorId}',
      );
      notifyListeners();

      // _onAuthStateChanged durumu güncelleyecek
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint('AuthProvider signUpWithInviteCode FirebaseAuthException: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Kayıt sırasında bir hata oluştu: ${e.message}';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('AuthProvider signUpWithInviteCode hatası: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _errorMessage = null;
    // notifyListeners burada çağrılmaz — dialog pop() sırasında
    // senkron rebuild tetikleyip _dependents.isEmpty hatasına yol açar.

    try {
      await _authService.sendPasswordResetEmail(email.trim());
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      _errorMessage = switch (e.code) {
        'invalid-email' => 'Geçerli bir e-posta adresi girin.',
        'missing-email' => 'Lütfen e-posta adresinizi girin.',
        'user-not-found' =>
          'Bu e-posta ile kayıtlı bir kullanıcı bulunamadı.',
        _ => e.message ?? 'Şifre sıfırlama bağlantısı gönderilemedi.',
      };
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Şifre sıfırlama bağlantısı gönderilemedi.';
      notifyListeners();
      return false;
    }
  }
}
