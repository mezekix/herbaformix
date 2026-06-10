import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final userGoal = context.select<AuthProvider, String>(
      (ap) => ap.userProfile?.userGoal ?? 'healthy_living',
    );
    if (_loadedGoal != userGoal && !_loadingQuotes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadQuotes(userGoal);
      });
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF42A146), Color(0xFF266431)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF266431).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Söz bölümü
          Text(
            _distributorMessage ?? _displayedQuote,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _switchQuote,
            child: Row(
              children: [
                Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.6), size: 14),
                const SizedBox(width: 4),
                Text(
                  '✦ Başka bir söz için dokun',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_sessionSwitches > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${_maxSwitches - _sessionSwitches} hak)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_distributorName != null) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— ${_distributorName!.split(' ').first} (Distribütörün)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}