import 'package:flutter/foundation.dart';

import '../../../models/product_model.dart';
import '../../../models/user_profile_model.dart';
import '../models/program_model.dart';
import '../services/notification_service.dart';
import '../services/program_service.dart';

enum ProgramWizardStep {
  goalSelection,
  weightInput,
  mealPlan,
  summary,
}

class ProgramProvider with ChangeNotifier {
  final ProgramService _programService;
  final NotificationService _notificationService;

  ProgramProvider({
    ProgramService? programService,
    NotificationService? notificationService,
  })  : _programService = programService ?? ProgramService(),
        _notificationService = notificationService ?? NotificationService();

  // ── Wizard ────────────────────────────────────────────────────────────────
  ProgramWizardStep _currentStep = ProgramWizardStep.goalSelection;
  ProgramWizardStep get currentStep => _currentStep;

  String? _selectedGoal;
  String? get selectedGoal => _selectedGoal;

  double? _currentWeight;
  double? get currentWeight => _currentWeight;

  double? _targetWeight;
  double? get targetWeight => _targetWeight;

  int _durationMonths = 1;
  int get durationMonths => _durationMonths;

  // Slot listesi — ana + ara öğünler
  List<MealSlot> _slots = [];
  List<MealSlot> get slots => List.unmodifiable(_slots);

  // ── Aktif Program ─────────────────────────────────────────────────────────
  ProgramModel? _activeProgram;
  ProgramModel? get activeProgram => _activeProgram;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Wizard Navigasyonu ────────────────────────────────────────────────────
  void nextStep() {
    switch (_currentStep) {
      case ProgramWizardStep.goalSelection:
        _currentStep = _selectedGoal == 'weight_loss'
            ? ProgramWizardStep.weightInput
            : ProgramWizardStep.mealPlan;
      case ProgramWizardStep.weightInput:
        _currentStep = ProgramWizardStep.mealPlan;
      case ProgramWizardStep.mealPlan:
        _currentStep = ProgramWizardStep.summary;
      case ProgramWizardStep.summary:
        break;
    }
    notifyListeners();
  }

  void previousStep() {
    switch (_currentStep) {
      case ProgramWizardStep.goalSelection:
        break;
      case ProgramWizardStep.weightInput:
        _currentStep = ProgramWizardStep.goalSelection;
      case ProgramWizardStep.mealPlan:
        _currentStep = _selectedGoal == 'weight_loss'
            ? ProgramWizardStep.weightInput
            : ProgramWizardStep.goalSelection;
      case ProgramWizardStep.summary:
        _currentStep = ProgramWizardStep.mealPlan;
    }
    notifyListeners();
  }

  // ── Hedef ─────────────────────────────────────────────────────────────────
  void setGoal(String goal) {
    _selectedGoal = goal;
    _currentWeight = null;
    _targetWeight = null;
    _durationMonths = 1;
    _slots = [];
    notifyListeners();
  }

  // ── Kilo ──────────────────────────────────────────────────────────────────
  void setWeights({required double current, required double target}) {
    _currentWeight = current;
    _targetWeight = target;
    try {
      _durationMonths = calculateMinDuration(current, target);
    } catch (_) {
      _durationMonths = 1;
    }
    notifyListeners();
  }

  void setDurationMonths(int months) {
    _durationMonths = months;
    notifyListeners();
  }

  int getMinDuration(double current, double target) =>
      calculateMinDuration(current, target);

  // ── Slot Yönetimi ─────────────────────────────────────────────────────────

  /// Varsayılan slotları oluşturur (sabah 09:00, öğle 13:00, akşam 19:00)
  void initSlots(String goal) {
    _slots = buildDefaultSlots(goal);
    notifyListeners();
  }

  /// Slot saatini güncelle
  void updateSlotTime(String slotId, String newTime) {
    _slots = _slots.map((s) {
      if (s.id == slotId) return s.copyWith(scheduledTime: newTime);
      return s;
    }).toList();
    notifyListeners();
  }

  /// Slot tipini değiştir (normal yemek / ürün)
  void toggleSlotNormalMeal(String slotId, bool isNormalMeal) {
    _slots = _slots.map((s) {
      if (s.id == slotId) {
        return s.copyWith(
          isNormalMeal: isNormalMeal,
          products: isNormalMeal ? [] : s.products,
        );
      }
      return s;
    }).toList();
    notifyListeners();
  }

  /// Slota ürün ekle
  void addProductToSlot(String slotId, MealProduct product) {
    debugPrint('[Provider] addProductToSlot: slotId=$slotId, product=${product.productName}, mevcut slots=${_slots.map((s) => "${s.id}:${s.products.length}").join(", ")}');
    _slots = _slots.map((s) {
      if (s.id == slotId) {
        // Aynı ürün zaten varsa ekleme
        if (s.products.any((p) => p.productId == product.productId)) return s;
        return s.copyWith(products: [...s.products, product]);
      }
      return s;
    }).toList();
    notifyListeners();
  }

  /// Slottan ürün kaldır
  void removeProductFromSlot(String slotId, String productId) {
    _slots = _slots.map((s) {
      if (s.id == slotId) {
        return s.copyWith(
          products: s.products.where((p) => p.productId != productId).toList(),
        );
      }
      return s;
    }).toList();
    notifyListeners();
  }

  /// Yeni ara öğün ekle
  void addSnackSlot() {
    final snackCount = _slots.where((s) => s.kind == MealSlotKind.snack).length;
    final newSlot = MealSlot(
      id: 'snack_${DateTime.now().millisecondsSinceEpoch}',
      kind: MealSlotKind.snack,
      label: 'Ara Öğün ${snackCount + 1}',
      scheduledTime: '10:30',
      isNormalMeal: false,
      products: [],
    );
    _slots = [..._slots, newSlot];
    notifyListeners();
  }

  /// Slot sil (yalnızca ara öğünler silinebilir)
  void removeSlot(String slotId) {
    _slots = _slots.where((s) => s.id != slotId).toList();
    notifyListeners();
  }

  // ── Program Kaydetme ──────────────────────────────────────────────────────
  Future<bool> saveProgram(
    String userId,
    List<ProductModel> allProducts, {
    bool scheduleNotifications = true,
  }) async {
    debugPrint('[ProgramProvider] saveProgram başlıyor: userId=$userId, slots=${_slots.length}, goal=$_selectedGoal');
    for (final s in _slots) {
      debugPrint('  slot: ${s.id} | ${s.label} | products=${s.products.length} | normalMeal=${s.isNormalMeal}');
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (scheduleNotifications) {
        await _notificationService.cancelAllProgramNotifications();
      }

      final now = DateTime.now();
      final program = ProgramModel(
        id: 'active',
        userGoal: _selectedGoal ?? 'healthy_living',
        startDate: now,
        durationMonths: _durationMonths,
        slots: _slots,
        currentWeight: _selectedGoal == 'weight_loss' ? _currentWeight : null,
        targetWeight: _selectedGoal == 'weight_loss' ? _targetWeight : null,
        createdAt: now,
        isActive: true,
      );

      await _programService.saveProgram(userId, program, allProducts);
      if (scheduleNotifications) {
        await _scheduleNotifications(program);
      }

      _activeProgram = program;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ProgramProvider] saveProgram HATA: $e');
      _errorMessage = 'Program kaydedilemedi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Belirtilen hedefe ve kilo bilgilerine göre otomatik program oluşturur.
  Future<bool> createAutomaticProgram({
    required String userId,
    required String userGoal,
    required double? currentWeight,
    required double? targetWeight,
    required List<ProductModel> allProducts,
    bool scheduleNotifications = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedGoal = userGoal;
      _currentWeight = currentWeight;
      _targetWeight = targetWeight;

      if (userGoal == 'weight_loss' && currentWeight != null && targetWeight != null) {
        try {
          _durationMonths = calculateMinDuration(currentWeight, targetWeight);
        } catch (_) {
          _durationMonths = 1;
        }
      } else {
        _durationMonths = 1;
      }

      _slots = buildDefaultSlots(userGoal);

      final result = await saveProgram(
        userId,
        allProducts,
        scheduleNotifications: scheduleNotifications,
      );
      return result;
    } catch (e) {
      debugPrint('[ProgramProvider] createAutomaticProgram HATA: $e');
      _errorMessage = 'Otomatik program oluşturulamadı: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _scheduleNotifications(ProgramModel program) async {
    await _notificationService.initialize();
    
    for (final slot in program.slots) {
      // 1. Ana Slot için bildirim (Ürün, Normal Öğün veya Ara Öğün fark etmeksizin)
      final id = getMealNotificationId(slot.id);
      String title = '⏰ ${slot.label} Zamanı!';
      String body = 'Öğününüzü/Ürününüzü almayı unutmayın.';
      
      if (slot.products.isNotEmpty) {
        final productNames = slot.products.map((p) => p.productName).join(', ');
        title = '🥤 ${slot.label} Zamanı!';
        body = '$productNames kullanmayı unutmayın.';
      } else if (slot.isNormalMeal) {
        title = '🍽️ ${slot.label} Zamanı!';
        body = 'Sağlıklı bir öğün tüketmeyi unutmayın.';
      } else {
        title = '🍎 ${slot.label} Zamanı!';
        body = 'Ara öğün zamanı geldi, atıştırmalığınızı unutmayın.';
      }
      
      await _notificationService.scheduleMealNotification(
        notificationId: id,
        title: title,
        body: body,
        scheduledTime: slot.scheduledTime,
      );

      // 2. Öğün (snack değilse) için 30 dk öncesine SU bildirimi
      if (slot.kind != MealSlotKind.snack) {
        final timeParts = slot.scheduledTime.split(':');
        if (timeParts.length == 2) {
          final mealHour = int.tryParse(timeParts[0]) ?? 0;
          final mealMinute = int.tryParse(timeParts[1]) ?? 0;
          final now = DateTime.now();
          final mealTime = DateTime(now.year, now.month, now.day, mealHour, mealMinute);
          final waterTime = mealTime.subtract(const Duration(minutes: 30));
          
          final waterScheduledTime = '${waterTime.hour.toString().padLeft(2, '0')}:${waterTime.minute.toString().padLeft(2, '0')}';
          // Su bildirimi için slot id'sine özel benzersiz bir ID (100000 ekleyerek çakışmayı önlüyoruz)
          final waterId = id + 100000;
          
          await _notificationService.scheduleMealNotification(
            notificationId: waterId,
            title: '💧 Su Hatırlatıcısı',
            body: '${slot.label} öncesinde 1 büyük bardak (500ml) su içmeyi unutmayın.',
            scheduledTime: waterScheduledTime,
          );
        }
      }
    }
  }

  // ── Aktif Program ─────────────────────────────────────────────────────────
  Future<void> loadActiveProgram(String userId) async {
    _isLoading = true;
    notifyListeners();
    _activeProgram = await _programService.getActiveProgram(userId);
    _isLoading = false;
    notifyListeners();
  }

  Stream<ProgramModel?> watchActiveProgram(String userId) =>
      _programService.watchActiveProgram(userId);

  Future<void> deleteProgram(String userId) async {
    _isLoading = true;
    notifyListeners();
    await _notificationService.cancelAllProgramNotifications();
    await _programService.deleteProgram(userId);
    _activeProgram = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> hasActiveProgram(String userId) =>
      _programService.hasActiveProgram(userId);

  /// Aktif programa yeni slot ekle (program başladıktan sonra)
  Future<bool> addSlotToActiveProgram(
    String userId,
    MealSlot newSlot,
    List<ProductModel> allProducts, {
    bool scheduleNotifications = true,
  }) async {
    // _activeProgram null ise Firestore'dan çek
    if (_activeProgram == null) {
      debugPrint('[ProgramProvider] _activeProgram null, Firestore\'dan çekiliyor...');
      _activeProgram = await _programService.getActiveProgram(userId);
      if (_activeProgram == null) {
        debugPrint('[ProgramProvider] Firestore\'da da aktif program yok!');
        return false;
      }
    }
    _isLoading = true;
    notifyListeners();
    try {
      final updated = _activeProgram!.copyWith(
        slots: [..._activeProgram!.slots, newSlot],
      );
      await _programService.saveProgram(userId, updated, allProducts);
      
      if (scheduleNotifications) {
        await _notificationService.cancelAllProgramNotifications();
        await _scheduleNotifications(updated);
      }

      _activeProgram = updated;
      _isLoading = false;
      notifyListeners();
      debugPrint('[ProgramProvider] Slot eklendi ve bildirimler yeniden zamanlandı.');
      return true;
    } catch (e) {
      debugPrint('[ProgramProvider] addSlotToActiveProgram hatası: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Aktif programdan bir slotu siler
  Future<bool> removeSlotFromActiveProgram(
    String userId,
    String slotId,
    List<ProductModel> allProducts, {
    bool scheduleNotifications = true,
  }) async {
    // _activeProgram null ise Firestore'dan çek
    if (_activeProgram == null) {
      _activeProgram = await _programService.getActiveProgram(userId);
      if (_activeProgram == null) return false;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final updatedSlots = _activeProgram!.slots.where((s) => s.id != slotId).toList();
      final updated = _activeProgram!.copyWith(slots: updatedSlots);
      
      await _programService.saveProgram(userId, updated, allProducts);
      
      if (scheduleNotifications) {
        await _notificationService.cancelAllProgramNotifications();
        await _scheduleNotifications(updated);
      }

      _activeProgram = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ProgramProvider] removeSlotFromActiveProgram hatası: $e');
      _errorMessage = 'Öğün silinirken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void resetWizard() {
    _currentStep = ProgramWizardStep.goalSelection;
    _selectedGoal = null;
    _currentWeight = null;
    _targetWeight = null;
    _durationMonths = 1;
    _slots = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Sadece adımı sıfırla, diğer state'i koru
  void goToFirstStep() {
    _currentStep = ProgramWizardStep.goalSelection;
    _errorMessage = null;
    notifyListeners();
  }

  /// Profil bilgilerine göre wizard state'ini doldurur ve adımı belirler.
  void initializeWizardWithProfile(UserProfileModel? profile) {
    if (profile == null) {
      resetWizard();
      return;
    }

    final goal = profile.userGoal ?? profile.goal;
    final isGoalSelected = goal != null && goal.isNotEmpty;
    final isPhysicalInfoEntered = profile.weight != null && profile.targetWeight != null;

    if (isGoalSelected) {
      _selectedGoal = goal;
      
      if (isPhysicalInfoEntered) {
        _currentWeight = profile.weight;
        _targetWeight = profile.targetWeight;
        try {
          _durationMonths = calculateMinDuration(profile.weight!, profile.targetWeight!);
        } catch (_) {
          _durationMonths = 1;
        }
        
        // Bilgiler tamsa direkt Öğün Planı adımına geç
        _currentStep = ProgramWizardStep.mealPlan;
      } else {
        // Hedef seçilmiş ama kilo bilgileri yoksa (kilo verme/kilo alma hedefleri için kilo girişi adımına geç)
        if (goal == 'weight_loss') {
          _currentStep = ProgramWizardStep.weightInput;
        } else {
          _currentStep = ProgramWizardStep.mealPlan;
        }
      }
    } else {
      // Hiçbir şey seçilmemişse baştan başla
      _currentStep = ProgramWizardStep.goalSelection;
    }
    
    _errorMessage = null;
    notifyListeners();
  }
}
