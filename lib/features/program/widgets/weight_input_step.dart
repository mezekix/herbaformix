import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../models/program_model.dart';
import '../providers/program_provider.dart';

class WeightInputStep extends StatefulWidget {
  const WeightInputStep({super.key});

  @override
  State<WeightInputStep> createState() => _WeightInputStepState();
}

class _WeightInputStepState extends State<WeightInputStep> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _targetController = TextEditingController();
  String? _validationError;
  int? _calculatedMinDuration;

  @override
  void dispose() {
    _currentController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _onWeightChanged() {
    final current = double.tryParse(_currentController.text);
    final target = double.tryParse(_targetController.text);
    if (current != null && target != null) {
      try {
        final min = calculateMinDuration(current, target);
        setState(() {
          _calculatedMinDuration = min;
          _validationError = null;
        });
      } catch (_) {
        setState(() {
          _calculatedMinDuration = null;
          _validationError = 'Hedef kilo mevcut kilodan küçük olmalıdır.';
        });
      }
    } else {
      setState(() => _calculatedMinDuration = null);
    }
  }

  void _onNext(ProgramProvider provider) {
    if (!_formKey.currentState!.validate()) return;

    final current = double.parse(_currentController.text);
    final target = double.parse(_targetController.text);

    if (current <= target) {
      setState(() {
        _validationError = 'Hedef kilo mevcut kilodan küçük olmalıdır.';
      });
      return;
    }

    provider.setWeights(current: current, target: target);

    // Kullanıcı süreyi artırmak isteyebilir — provider'daki değeri kullan
    provider.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgramProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Kilo bilgilerini gir',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hedef kilona göre program süren otomatik hesaplanacak.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // Mevcut kilo
            _WeightField(
              controller: _currentController,
              label: 'Mevcut Kilonuz (kg)',
              hint: 'Örn: 80',
              icon: Icons.monitor_weight_outlined,
              onChanged: (_) => _onWeightChanged(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Lütfen mevcut kilonuzu girin.';
                if (double.tryParse(v) == null) return 'Geçerli bir sayı girin.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Hedef kilo
            _WeightField(
              controller: _targetController,
              label: 'Hedef Kilonuz (kg)',
              hint: 'Örn: 70',
              icon: Icons.flag_outlined,
              onChanged: (_) => _onWeightChanged(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Lütfen hedef kilonuzu girin.';
                if (double.tryParse(v) == null) return 'Geçerli bir sayı girin.';
                return null;
              },
            ),

            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Hesaplanan süre kartı
            if (_calculatedMinDuration != null) ...[
              const SizedBox(height: 24),
              _DurationCard(
                minDuration: _calculatedMinDuration!,
                selectedDuration: provider.durationMonths,
                onChanged: (val) => provider.setDurationMonths(val),
              ),
            ],

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () => _onNext(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Devam Et',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  const _WeightField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixText: 'kg',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final int minDuration;
  final int selectedDuration;
  final ValueChanged<int> onChanged;

  const _DurationCard({
    required this.minDuration,
    required this.selectedDuration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Program Süresi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.nightSky,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Minimum $minDuration ay önerilir.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Süreyi kısalt',
                onPressed: selectedDuration > minDuration
                    ? () => onChanged(selectedDuration - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
                iconSize: 32,
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    '$selectedDuration',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'ay',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                tooltip: 'Süreyi uzat',
                onPressed: () => onChanged(selectedDuration + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
