import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/program/providers/program_provider.dart';

class MotivationWidget extends StatefulWidget {
  const MotivationWidget({super.key});

  @override
  State<MotivationWidget> createState() => _MotivationWidgetState();
}

class _MotivationWidgetState extends State<MotivationWidget> {
  List<String> _quotes = [
    'Başlamak için mükemmel olmak zorunda değilsin.',
    'Her sabah yeniden doğarsın.',
    'Küçük adımlar büyük değişimlerin tohumudur.',
    'Başarı, küçük zaferlerin birikimidir.',
    'Bugün attığın her adım yarınki senini şekillendirir.',
  ];
  int _currentIndex = 0;
  int _sessionSwitches = 0;
  static const int _maxSwitches = 5;
  String? _distributorMessage;
  String? _distributorName;
  String? _loadedGoal;
  bool _loadingQuotes = false;

  @override
  void initState() {
    super.initState();
    _loadDistributorMessage();
  }

  Future<void> _loadQuotes(String userGoal) async {
    if (_loadingQuotes || _loadedGoal == userGoal) return;
    _loadingQuotes = true;
    try {
      final jsonString = await rootBundle.loadString('assets/motivations.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      final List<dynamic> quotesList =
          data[userGoal] ?? data['healthy_living'] ?? [];

      if (!mounted) return;
      setState(() {
        _quotes = quotesList.cast<String>();
        _loadedGoal = userGoal;
        _sessionSwitches = 0;
        if (_quotes.isNotEmpty) {
          final dayIndex = DateTime.now().millisecondsSinceEpoch ~/ 86400000 % _quotes.length;
          _currentIndex = dayIndex;
        } else {
          _currentIndex = 0;
        }
      });
    } catch (e) {
      debugPrint('loadQuotes hatası: $e');
    } finally {
      _loadingQuotes = false;
    }
  }

  Future<void> _loadDistributorMessage() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userProfile?.id;
    if (userId == null) return;

    final distributorId = authProvider.userProfile?.assignedDistributorId;
    if (distributorId == null) return;

    try {
      final message = await context.read<FirestoreService>().getDistributorMotivationMessage(userId);
      if (mounted && message != null) {
        final distributor = await context.read<FirestoreService>().getDistributorProfile(distributorId);
        if (mounted) {
          setState(() {
            _distributorMessage = message;
            _distributorName = distributor?.name ?? 'Distribütörün';
          });
        }
      }
    } catch (e) {
      debugPrint('loadDistributorMessage hatası: $e');
    }
  }

  void _switchQuote() {
    if (_sessionSwitches >= _maxSwitches) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yarın yeni sözler seni bekliyor'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _sessionSwitches++;
      _currentIndex = (_currentIndex + 1) % _quotes.length;
    });
  }

  String get _displayedQuote => _quotes.isEmpty ? '' : _quotes[_currentIndex];

  /// Cilt bakımı profil hedefi her zaman önceliklidir (programlar bu kategoriyi
  /// desteklemez). Aksi halde aktif programın hedefi profilinkini ezer.
  String _resolveGoal(String? profileGoal, String? programGoal) {
    if (profileGoal == 'skin_care') return 'skin_care';
    return programGoal ?? profileGoal ?? 'healthy_living';
  }

  ({List<Color> gradient, IconData icon, Color glow}) _styleForGoal(String goal) {
    switch (goal) {
      case 'weight_loss':
        return (
          gradient: const [Color(0xFF2E8B57), Color(0xFF1B5E20)],
          icon: Icons.local_fire_department_rounded,
          glow: const Color(0xFF1B5E20),
        );
      case 'weight_gain':
        return (
          gradient: const [Color(0xFFE65100), Color(0xFFBF360C)],
          icon: Icons.fitness_center_rounded,
          glow: const Color(0xFFBF360C),
        );
      case 'skin_care':
        return (
          gradient: const [Color(0xFFAD1457), Color(0xFF6A1B4D)],
          icon: Icons.auto_awesome_rounded,
          glow: const Color(0xFF6A1B4D),
        );
      case 'healthy_living':
      default:
        return (
          gradient: const [Color(0xFF42A146), Color(0xFF266431)],
          icon: Icons.spa_rounded,
          glow: const Color(0xFF266431),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileGoal = context.select<AuthProvider, String?>(
      (ap) => ap.userProfile?.userGoal,
    );
    final programGoal = context.select<ProgramProvider, String?>(
      (pp) => pp.activeProgram?.userGoal,
    );
    final userGoal = _resolveGoal(profileGoal, programGoal);

    if (_loadedGoal != userGoal && !_loadingQuotes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadQuotes(userGoal);
      });
    }

    final style = _styleForGoal(userGoal);
    final isDistributorMsg = _distributorMessage != null;
    final shownQuote = _distributorMessage ?? _displayedQuote;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Ana gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: style.gradient,
                  ),
                ),
              ),
            ),
            // Üst sağ ışıltı
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Alt sol ışıltı
            Positioned(
              bottom: -50,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Dekoratif tırnak işareti
            Positioned(
              top: 8,
              left: 16,
              child: Text(
                '“',
                style: TextStyle(
                  fontSize: 90,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isDistributorMsg ? Icons.favorite_rounded : style.icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isDistributorMsg ? 'Sana Özel Mesaj' : 'Günün Sözü',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder: (child, anim) {
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOut,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      shownQuote,
                      key: ValueKey('$_loadedGoal-$_currentIndex-$isDistributorMsg'),
                      style: TextStyle(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.97),
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!isDistributorMsg)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _switchQuote,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Yeni söz',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_sessionSwitches > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_maxSwitches - _sessionSwitches}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_distributorName != null) ...[
                    const SizedBox(height: 16),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.18),
                      height: 1,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '— ${_distributorName!.split(' ').first} (Distribütörün)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
