import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/scheduled_follow_up_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/routine_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../program/services/program_service.dart';

/// Kritik aksiyonlar listesi için filtre seçenekleri.
enum ActionFilter { all, overdue, returnRisk, measurement }

/// Ana sayfanın ihtiyaç duyduğu verileri ve durumu yöneten Provider.
class HomeProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthProvider _authProvider;
  final RoutineService _routineService = RoutineService();

  String? _currentUserId;
  StreamSubscription<List<ScheduledFollowUpModel>>? _upcomingFollowUpsSubscription;

  List<ScheduledFollowUpModel> _allFollowUps = [];

  ActionFilter _activeFilter = ActionFilter.all;
  ActionFilter get activeFilter => _activeFilter;

  List<ScheduledFollowUpModel> get upcomingFollowUps {
    switch (_activeFilter) {
      case ActionFilter.all:
        return _allFollowUps;
      case ActionFilter.overdue:
        return _allFollowUps
            .where((f) => f.dueDate.toDate().isBefore(DateTime.now()))
            .toList();
      case ActionFilter.returnRisk:
        final keywords = ['iade', '3. gün', '7. gün', 'ilk hafta', 'başlangıç'];
        return _allFollowUps.where((f) {
          final title = f.title.toLowerCase();
          return keywords.any((kw) => title.contains(kw));
        }).toList();
      case ActionFilter.measurement:
        final keywords = ['ölçüm', 'kilo', 'tartı', 'beden', 'ölç'];
        return _allFollowUps.where((f) {
          final title = f.title.toLowerCase();
          return keywords.any((kw) => title.contains(kw));
        }).toList();
    }
  }

  int get overdueCount =>
      _allFollowUps.where((f) => f.dueDate.toDate().isBefore(DateTime.now())).length;

  int get allCount => _allFollowUps.length;

  /// Bugün (00:00 – 23:59 arası) vadesi olan tüm follow-up sayısı.
  /// Dashboard'daki "Bugün'ün Aksiyonları" çağırıcı chip'i için.
  int get dueTodayCount {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _allFollowUps.where((f) {
      final d = f.dueDate.toDate();
      return !d.isBefore(start) && d.isBefore(end);
    }).length;
  }

  int get returnRiskCount {
    final keywords = ['iade', '3. gün', '7. gün', 'ilk hafta', 'başlangıç'];
    return _allFollowUps.where((f) {
      final title = f.title.toLowerCase();
      return keywords.any((kw) => title.contains(kw));
    }).length;
  }

  int get measurementCount {
    final keywords = ['ölçüm', 'kilo', 'tartı', 'beden', 'ölç'];
    return _allFollowUps.where((f) {
      final title = f.title.toLowerCase();
      return keywords.any((kw) => title.contains(kw));
    }).length;
  }

  void setFilter(ActionFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _completionStreak = 0;
  int get completionStreak => _completionStreak;

  HomeProvider(this._firestoreService, this._authProvider) {
    _currentUserId = _authProvider.firebaseUser?.uid;
    _authProvider.addListener(_authListener);
    if (_currentUserId != null) {
      ProgramService().ensureTodayRoutines(_currentUserId!);
      _listenToUpcomingFollowUps(_currentUserId!);
      _loadStreak(_currentUserId!);
    }
  }

  void _authListener() {
    final newUserId = _authProvider.firebaseUser?.uid;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _upcomingFollowUpsSubscription?.cancel();
      _allFollowUps = [];
      _completionStreak = 0;
      if (_currentUserId != null) {
        ProgramService().ensureTodayRoutines(_currentUserId!);
        _listenToUpcomingFollowUps(_currentUserId!);
        _loadStreak(_currentUserId!);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadStreak(String userId) async {
    try {
      final streak = await _routineService.getCompletionStreak(userId);
      _completionStreak = streak;
      notifyListeners();
    } catch (e) {
      debugPrint('HomeProvider streak yüklenirken hata: $e');
    }
  }

  Future<void> refreshStreak() async {
    if (_currentUserId != null) {
      await _loadStreak(_currentUserId!);
    }
  }

  void _listenToUpcomingFollowUps(String userId) {
    _isLoading = true;
    notifyListeners();

    _upcomingFollowUpsSubscription?.cancel();

    // 30 güne kadar olan takipleri çek (1,3,7,15,30 gün planı için)
    final inTheNext = DateTime.now().add(const Duration(days: 30));

    _upcomingFollowUpsSubscription = _firestoreService
        .getUpcomingFollowUpsForConsultant(userId, inTheNext)
        .listen(
          (data) {
            _allFollowUps = data;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('HomeProvider Hata (listenToUpcomingFollowUps): $error');
            _isLoading = false;
            _allFollowUps = [];
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _upcomingFollowUpsSubscription?.cancel();
    _authProvider.removeListener(_authListener);
    super.dispose();
  }
}
