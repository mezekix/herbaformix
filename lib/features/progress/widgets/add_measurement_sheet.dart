import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/progress_entry_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/progress_provider.dart';

/// Kilo ve vücut ölçümü girişi için bottom sheet.
class AddMeasurementSheet extends StatefulWidget {
  const AddMeasurementSheet({super.key});

  @override
  State<AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();

  bool _showMeasurements = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _chestCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();
    final userId = authProvider.firebaseUser?.uid;
    final userProfile = authProvider.userProfile;

    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    final entry = ProgressEntryModel(
      id: '',
      date: DateTime.now(),
      weight: double.parse(_weightCtrl.text.replaceAll(',', '.')),
      waist: _waistCtrl.text.isNotEmpty
          ? double.tryParse(_waistCtrl.text.replaceAll(',', '.'))
          : null,
      hip: _hipCtrl.text.isNotEmpty
          ? double.tryParse(_hipCtrl.text.replaceAll(',', '.'))
          : null,
      chest: _chestCtrl.text.isNotEmpty
          ? double.tryParse(_chestCtrl.text.replaceAll(',', '.'))
          : null,
    );

    try {
      await progressProvider.addEntry(userId, entry, userProfile);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt eklenemedi. Tekrar deneyin.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Başlık
            const Text(
              'Yeni Ölçüm Ekle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bugünkü ölçümlerini gir',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),

            // Kilo alanı (zorunlu)
            _buildField(
              controller: _weightCtrl,
              label: 'Kilo (kg)',
              hint: 'Örn: 72.5',
              icon: Icons.monitor_weight_outlined,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Vücut ölçümleri toggle
            GestureDetector(
              onTap: () =>
                  setState(() => _showMeasurements = !_showMeasurements),
              child: Row(
                children: [
                  Icon(
                    _showMeasurements
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vücut Ölçümleri (opsiyonel)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            if (_showMeasurements) ...[
              const SizedBox(height: 16),
              _buildField(
                controller: _waistCtrl,
                label: 'Bel (cm)',
                hint: 'Örn: 82',
                icon: Icons.straighten,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _hipCtrl,
                label: 'Kalça (cm)',
                hint: 'Örn: 104',
                icon: Icons.straighten,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _chestCtrl,
                label: 'Göğüs (cm)',
                hint: 'Örn: 96',
                icon: Icons.straighten,
              ),
            ],

            const SizedBox(height: 28),

            // Kaydet butonu
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: isRequired
          ? (v) {
              if (v == null || v.trim().isEmpty) return 'Kilo zorunludur';
              final val = double.tryParse(v.replaceAll(',', '.'));
              if (val == null || val <= 0) return 'Geçerli bir değer girin';
              return null;
            }
          : (v) {
              if (v != null && v.isNotEmpty) {
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Geçerli bir değer girin';
              }
              return null;
            },
    );
  }
}
