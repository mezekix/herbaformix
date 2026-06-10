import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../services/repositories/program_template_repository.dart';
import '../models/program_template_model.dart';

/// Program şablonlarının liste cache'i ve CRUD aksiyonları.
///
/// Aynı oturumda birden fazla ekran (Şablonlar Ekranı, CreateProgram Sheet)
/// şablonları okuyup yenileyebilir; tek bir cache ile çift Firestore çağrısını
/// önler.
class ProgramTemplateProvider with ChangeNotifier {
  ProgramTemplateProvider({ProgramTemplateRepository? repository})
      : _repo = repository ?? ProgramTemplateRepository();

  final ProgramTemplateRepository _repo;

  List<ProgramTemplateModel> _templates = [];
  List<ProgramTemplateModel> get templates => List.unmodifiable(_templates);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<ProgramTemplateModel>>? _subscription;
  String? _watchedDistributorId;

  /// Belirli bir distribütörün şablonlarını dinlemeye başlar.
  /// Halihazırda aynı distribütör için dinleniyorsa idempotent.
  void watchForDistributor(String distributorId) {
    if (_watchedDistributorId == distributorId && _subscription != null) {
      return;
    }
    _watchedDistributorId = distributorId;
    _subscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription =
        _repo.watchByDistributor(distributorId).listen((list) {
      _templates = list;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('[ProgramTemplateProvider] watch hatası: $e');
      _isLoading = false;
      _errorMessage = 'Şablonlar yüklenemedi: $e';
      notifyListeners();
    });
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
    _watchedDistributorId = null;
  }

  Future<String?> create(ProgramTemplateModel template) async {
    try {
      final id = await _repo.create(template);
      return id;
    } catch (e) {
      debugPrint('[ProgramTemplateProvider] create hatası: $e');
      _errorMessage = 'Şablon oluşturulamadı: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> update(ProgramTemplateModel template) async {
    try {
      await _repo.update(template);
      return true;
    } catch (e) {
      debugPrint('[ProgramTemplateProvider] update hatası: $e');
      _errorMessage = 'Şablon güncellenemedi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      return true;
    } catch (e) {
      debugPrint('[ProgramTemplateProvider] delete hatası: $e');
      _errorMessage = 'Şablon silinemedi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<ProgramTemplateModel?> getById(String id) => _repo.getById(id);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
