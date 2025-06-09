import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:herbaformix/models/scheduled_follow_up_model.dart';

import '../../../models/follow_up_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Belirli bir müşterinin takip görüşmelerini (follow-ups) yöneten Provider.
///
/// Bu Provider, ChangeNotifierProvider.value ile anlık olarak oluşturulup
/// yok edileceği için, dinleyicileri (listener) manuel olarak yönetmek
/// yerine `ChangeNotifier`'ın temel özelliklerini kullanır.
class FollowUpProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final String _userId;
  final String _customerId;

  /// Bu provider'a bağlı olan anlık veri akışı (stream) aboneliği.
  StreamSubscription<List<FollowUpModel>>? _followUpsSubscription;

  /// Müşteriye ait takip görüşmelerinin listesi.
  List<FollowUpModel> _followUps = [];
  List<FollowUpModel> get followUps => _followUps;

  /// Planlanmış takip görüşmelerinin listesi.
  StreamSubscription<List<ScheduledFollowUpModel>>?
  _scheduledFollowUpsSubscription;
  List<ScheduledFollowUpModel> _scheduledFollowUps = [];
  List<ScheduledFollowUpModel> get scheduledFollowUps => _scheduledFollowUps;

  /// Sadece tamamlanmamış planlanmış takipleri döndüren bir getter.
  List<ScheduledFollowUpModel> get pendingScheduledFollowUps =>
      _scheduledFollowUps.where((sf) => !sf.isCompleted).toList();

  /// Verilerin yüklenip yüklenmediğini belirten bayrak.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FollowUpProvider({
    required AuthProvider authProvider,
    required FirestoreService firestoreService,
    required String customerId,
  }) : _firestoreService = firestoreService,
       _userId = authProvider.firebaseUser?.uid ?? '',
       _customerId = customerId {
    // Eğer kullanıcı ID'si veya müşteri ID'si boş ise işlem yapma.
    if (_userId.isNotEmpty && _customerId.isNotEmpty) {
      _listenToFollowUps();
      _listenToScheduledFollowUps(); // Yeni stream dinleyicisini çağır.
    }
  }

  /// Firestore'dan gelen anlık takip verilerini dinler.
  void _listenToFollowUps() {
    _isLoading = true;
    notifyListeners(); // Arayüzü "yükleniyor" durumuna geçir.

    // Önceki aboneliği (varsa) iptal et.
    _followUpsSubscription?.cancel();

    // Firestore servisinden ilgili müşteri için stream'i al ve dinlemeye başla.
    _followUpsSubscription = _firestoreService
        .getFollowUps(_userId, _customerId)
        .listen(
          (followUpsData) {
            _followUps = followUpsData; // Gelen veriyi lokale ata.
            _isLoading = false;
            notifyListeners(); // Arayüzü yeni veriyle ve "yükleme bitti" durumuyla güncelle.
          },
          onError: (error) {
            print("FollowUpProvider Hata (listenToFollowUps): $error");
            _isLoading = false;
            _followUps = []; // Hata durumunda listeyi temizle.
            notifyListeners(); // Arayüzü hata durumuyla güncelle.
          },
        );
  }

  /// Firestore'dan gelen anlık PLANLANMIŞ takip verilerini dinler.
  void _listenToScheduledFollowUps() {
    if (_userId.isEmpty) {
      print(
        "FollowUpProvider Hata: Kullanıcı ID'si boş olduğu için planlanmış takipler dinlenemiyor.",
      );
      _isLoading = false;
      _scheduledFollowUps = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    _scheduledFollowUpsSubscription?.cancel();
    _scheduledFollowUpsSubscription = _firestoreService
        .getScheduledFollowUpsForCustomer(_userId, _customerId)
        .listen(
          (scheduledData) {
            _scheduledFollowUps = scheduledData;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            print("FollowUpProvider Hata (listenToScheduledFollowUps): $error");
            _isLoading = false;
            _scheduledFollowUps = [];
            notifyListeners();
          },
        );
  }

  /// Yeni bir takip görüşmesi ekler.
  /// Opsiyonel olarak, bu görüşmenin tamamladığı planlanmış görevin ID'sini alır.
  Future<bool> addFollowUp(
    FollowUpModel followUp, {
    String? completedScheduledFollowUpId,
  }) async {
    if (_userId.isEmpty) return false;
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.addFollowUp(_userId, _customerId, followUp);

      // Eğer bu ekleme, planlanmış bir görevi tamamlıyorsa, o görevi güncelle.
      if (completedScheduledFollowUpId != null &&
          completedScheduledFollowUpId.isNotEmpty) {
        await _firestoreService.markScheduledFollowUpAsCompleted(
          completedScheduledFollowUpId,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("FollowUpProvider Hata (addFollowUp): $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mevcut bir takip görüşmesini günceller.
  Future<bool> updateFollowUp(FollowUpModel followUp) async {
    if (_userId.isEmpty || _customerId.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Modeli direkt olarak `updateFollowUp` servisine gönderiyoruz.
      await _firestoreService.updateFollowUp(_userId, _customerId, followUp);
      return true;
    } catch (e) {
      print("FollowUpProvider Hata (updateFollowUp): $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Belirtilen ID'ye sahip bir takip görüşmesini siler.
  Future<bool> deleteFollowUp(String followUpId) async {
    // Kullanıcı ID'si veya müşteri ID'si yoksa işlemi iptal et.
    if (_userId.isEmpty || _customerId.isEmpty) return false;

    // Arayüzde bir yüklenme durumu göstermek için (opsiyonel ama iyi bir pratik)
    _isLoading = true;
    notifyListeners();

    try {
      // Firestore servisi aracılığıyla silme işlemini gerçekleştir.
      await _firestoreService.deleteFollowUp(_userId, _customerId, followUpId);
      // Not: Stream (anlık veri akışı) sayesinde liste otomatik olarak güncellenecektir.
      // Bu yüzden lokal listeyi manuel olarak düzenlememize gerek yok.
      return true;
    } catch (e) {
      print("FollowUpProvider Hata (deleteFollowUp): $e");
      return false; // Hata durumunda false döndür.
    } finally {
      // İşlem başarılı da olsa, başarısız da olsa yüklenme durumunu kapat.
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Provider temizlendiğinde (dispose) tüm abonelikleri sonlandır.
  @override
  void dispose() {
    _followUpsSubscription?.cancel();
    _scheduledFollowUpsSubscription?.cancel(); // Yeni aboneliği de iptal et.
    super.dispose();
  }
}
