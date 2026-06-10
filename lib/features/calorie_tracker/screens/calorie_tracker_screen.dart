import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../providers/calorie_provider.dart';
import 'calorie_history_screen.dart';

class CalorieTrackerScreen extends StatelessWidget {
  static const routeName = 'calorie-tracker';
  const CalorieTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalori Sayacı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () =>
                context.goNamed(CalorieHistoryScreen.routeName),
            tooltip: 'Geçmiş',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showGoalDialog(context),
            tooltip: 'Hedefi Düzenle',
          ),
        ],
      ),
      body: Consumer<CalorieProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressCard(context, provider),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildMealList(context, provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(context),
        label: const Text('Öğün Ekle'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, CalorieProvider provider) {
    final textTheme = Theme.of(context).textTheme;
    final progress = provider.progress;
    final overGoal = provider.totalCalories > provider.calorieGoal;
    final color = overGoal ? Colors.orange : AppColors.primary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.totalCalories} / ${provider.calorieGoal}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Tüketilen Kalori (kcal)', style: textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  if (overGoal) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Hedefi ${provider.totalCalories - provider.calorieGoal} kcal aştın.',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  Widget _buildMealList(BuildContext context, CalorieProvider provider) {
    final meals = provider.meals;

    if (meals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Bugün hiç öğün eklenmedi.\nSağ alttaki (+) butonuyla başlayın.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bugünkü Öğünler',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meals.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final meal = meals[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              leading: const Icon(
                Icons.restaurant_menu,
                color: AppColors.primary,
              ),
              title: Text(
                meal.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(DateFormat('HH:mm').format(meal.timestamp)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${meal.calories} kcal',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => provider.removeMeal(meal.id),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddMealDialog(BuildContext context) {
    final provider = Provider.of<CalorieProvider>(context, listen: false);
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğün Ekle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Öğün Adı (Örn: Tavuklu Salata)',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Lütfen bir öğün adı girin.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: caloriesController,
                decoration: const InputDecoration(labelText: 'Kalori (kcal)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen kalori miktarı girin.';
                  }
                  final v = int.tryParse(value);
                  if (v == null || v <= 0) {
                    return 'Lütfen geçerli bir kalori değeri girin.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(context);
                final name = nameController.text;
                final calories = int.parse(caloriesController.text);
                await provider.addMeal(name, calories);
                navigator.pop();
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context) {
    final provider = Provider.of<CalorieProvider>(context, listen: false);
    final goalController = TextEditingController(
      text: provider.calorieGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlük Hedefi Düzenle'),
        content: TextFormField(
          controller: goalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Günlük Kalori Hedefi (kcal)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final newGoal = int.tryParse(goalController.text);
              if (newGoal != null && newGoal > 0) {
                await provider.setCalorieGoal(newGoal);
                navigator.pop();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
