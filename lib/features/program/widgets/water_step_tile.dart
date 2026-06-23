import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../features/water_tracker/providers/water_provider.dart';
import '../../../models/daily_routine_model.dart';
import '../../../services/routine_service.dart';

/// Su içme adımı için timeline kartı.
/// Tamamlandığında WaterProvider'a 500ml kaydeder.
class WaterStepTile extends StatelessWidget {
  final DailyRoutineModel routine;
  final String userId;
  final bool isLast;

  const WaterStepTile({
    super.key,
    required this.routine,
    required this.userId,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final accentColor = Colors.cyan.shade500;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline çizgisi
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: routine.isCompleted ? accentColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: routine.isCompleted
                          ? accentColor
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: routine.isCompleted
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    routine.isCompleted ? Icons.check : Icons.water_drop,
                    size: 16,
                    color: routine.isCompleted ? Colors.white : accentColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          // Kart
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: routine.isCompleted
                    ? Colors.cyan.shade50
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: routine.isCompleted
                      ? Colors.cyan.shade200
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1 Büyük Bardak Su',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: routine.isCompleted
                                ? Colors.cyan.shade700
                                : AppColors.nightSky,
                            fontSize: 14,
                            decoration: routine.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeFormat.format(routine.scheduledTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '500 ml',
                              style: TextStyle(
                                fontSize: 12,
                                color: accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: routine.isCompleted,
                    activeColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) async {
                      if (val == null) return;
                      
                      final routineService = context.read<RoutineService>();
                      final waterProvider = context.read<WaterProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      
                      // Rutin durumunu güncelle
                      await routineService.updateRoutineStatus(userId, routine.id, val);

                      // Su içildiyse WaterProvider'a kaydet, kaldırıldıysa sil
                      try {
                        if (val) {
                          waterProvider.addWater(500);
                        } else {
                          waterProvider.removeWater(500);
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Su kaydı yapılamadı, lütfen tekrar deneyin.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
