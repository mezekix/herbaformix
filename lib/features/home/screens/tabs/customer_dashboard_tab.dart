import 'package:flutter/material.dart';

import '../../../../models/daily_routine_model.dart';
import '../views/customer_dashboard_view.dart';

class CustomerDashboardTab extends StatelessWidget {
  const CustomerDashboardTab({
    super.key,
    required this.routinesStream,
    required this.onNavigateToProgram,
  });

  final Stream<List<DailyRoutineModel>>? routinesStream;
  final VoidCallback onNavigateToProgram;

  @override
  Widget build(BuildContext context) {
    return CustomerDashboardView(
      routinesStream: routinesStream,
      onNavigateToProgram: onNavigateToProgram,
    );
  }
}
