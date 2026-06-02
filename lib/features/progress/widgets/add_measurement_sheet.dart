import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/progress_entry_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/progress_provider.dart';

/// Kilo ve vücut ölçümü girişi için bottom sheet.
class AddMeasurementSheet extends StatefulWidget {
  final ProgressEntryModel? entry;

  const AddMeasurementSheet({super.key, this.entry});

  @override
  State<AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _muscleMassCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  final _thighCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  bool _showMeasurements = false;
  bool _isSaving = false;
  bool _needsHeight = false;
  late DateTime _selectedDate;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.entry?.date ?? DateTime.now();
    final e = widget.entry;
    if (e != null) {
      _weightCtrl.text = e.weight.toString();
      _waistCtrl.text = e.waist?.toString() ?? '';
      _hipCtrl.text = e.hip?.toString() ?? '';
      _chestCtrl.text = e.chest?.toString() ?? '';
      _bodyFatCtrl.text = e.bodyFat?.toString() ?? '';
      _muscleMassCtrl.text = e.muscleMass?.toString() ?? '';
      _armCtrl.text = e.arm?.toString() ?? '';
      _thighCtrl.text = e.thigh?.toString() ?? '';
      if (e.waist != null || e.hip != null || e.chest != null ||
          e.bodyFat != null || e.muscleMass != null || e.arm != null || e.thigh != null) {
        _showMeasurements = true;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfile = context.read<AuthProvider>().userProfile;
      if (userProfile?.height == null || userProfile!.height! <= 0) {
        setState(() {
          _needsHeight = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _chestCtrl.dispose();
    _bodyFatCtrl.dispose();
    _muscleMassCtrl.dispose();
    _armCtrl.dispose();
    _thighCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();
    final userId = authProvider.firebaseUser?.uid;
    final userProfile = authProvider.userProfile;

    if (userId == null || userProfile == null) {
      setState(() => _isSaving = false);
      return;
    }

    if (_needsHeight) {
      final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
      if (h != null && h > 0) {
        userProfile.height = h;
        await authProvider.updateUserProfile(userProfile);
      }
    }

    final entry = ProgressEntryModel(
      id: _isEditing ? widget.entry!.id : '',
      date: _selectedDate,
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
      bodyFat: _bodyFatCtrl.text.isNotEmpty
          ? double.tryParse(_bodyFatCtrl.text.replaceAll(',', '.'))
          : null,
      muscleMass: _muscleMassCtrl.text.isNotEmpty
          ? double.tryParse(_muscleMassCtrl.text.replaceAll(',', '.'))
          : null,
      arm: _armCtrl.text.isNotEmpty
          ? double.tryParse(_armCtrl.text.replaceAll(',', '.'))
          : null,
      thigh: _thighCtrl.text.isNotEmpty
          ? double.tryParse(_thighCtrl.text.replaceAll(',', '.'))
          : null,
    );

    // Aynı gün tekrar kontrolü
    if (!_isEditing) {
      final hasSameDay = progressProvider.entries.any(
        (e) => e.date.year == _selectedDate.year &&
               e.date.month == _selectedDate.month &&
               e.date.day == _selectedDate.day,
      );
      if (hasSameDay) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Aynı Günde Kayıt'),
            content: const Text(
              'Bu tarihte zaten bir ölçüm kaydın var. Yine de eklemek istiyor musun?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Ekle', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
        if (!mounted || shouldContinue != true) {
          setState(() => _isSaving = false);
          return;
        }
      }
    }

    try {
      if (_isEditing) {
        await progressProvider.updateEntry(userId, entry);
      } else {
        await progressProvider.addEntry(userId, entry, userProfile);
      }
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
        child: SingleChildScrollView(
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
            Text(
              _isEditing ? 'Ölçümü Düzenle' : 'Yeni Ölçüm Ekle',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isEditing 
                ? 'Ölçüm bilgilerini güncelle' 
                : 'Bugünkü ölçümlerini gir',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),

            // Tarih seçici
            if (!_isEditing) ...[
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.nightSky,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Değiştir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Kilo alanı (zorunlu)
            _buildField(
              controller: _weightCtrl,
              label: 'Kilo (kg)',
              hint: 'Örn: 72.5',
              icon: Icons.monitor_weight_outlined,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            if (_needsHeight) ...[
              _buildField(
                controller: _heightCtrl,
                label: 'Boy (cm)',
                hint: 'Örn: 175',
                icon: Icons.height,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              Text(
                'BMI hesaplanabilmesi için boy bilgisine ihtiyacımız var. Bu bilgi profiline kaydedilecektir.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
            ],

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
              const SizedBox(height: 12),
              _buildField(
                controller: _armCtrl,
                label: 'Kol (cm)',
                hint: 'Örn: 32',
                icon: Icons.straighten,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _thighCtrl,
                label: 'Bacak (cm)',
                hint: 'Örn: 58',
                icon: Icons.straighten,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _bodyFatCtrl,
                label: 'Yağ Oranı (%)',
                hint: 'Örn: 25.3',
                icon: Icons.water_drop_outlined,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _muscleMassCtrl,
                label: 'Kas Kütlesi (kg)',
                hint: 'Örn: 45.0',
                icon: Icons.fitness_center,
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
                    : Text(
                        _isEditing ? 'Güncelle' : 'Kaydet',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
