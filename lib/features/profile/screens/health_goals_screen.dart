import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../utils/profile_validators.dart';

class HealthGoalsScreen extends StatefulWidget {
  static const String routeName = 'health-goals';

  const HealthGoalsScreen({super.key});

  @override
  State<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends State<HealthGoalsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _healthNotesController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _targetWeightController = TextEditingController();
    _healthNotesController = TextEditingController();
    _allergiesController = TextEditingController();
    _medicationsController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = authProvider.userProfile;

      if (userProfile != null) {
        if (userProfile.height != null) {
          _heightController.text = userProfile.height!.toString();
        }
        if (userProfile.weight != null) {
          _weightController.text = userProfile.weight!.toString();
        }
        if (userProfile.targetWeight != null) {
          _targetWeightController.text = userProfile.targetWeight!.toString();
        }
        _healthNotesController.text = userProfile.healthNotes ?? '';
        _allergiesController.text = userProfile.allergies ?? '';
        _medicationsController.text = userProfile.medications ?? '';
      }

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _healthNotesController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  UserProfileModel _buildUpdatedProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();
    final targetWeightText = _targetWeightController.text.trim();
    final healthNotesText = _healthNotesController.text.trim();
    final allergiesText = _allergiesController.text.trim();
    final medicationsText = _medicationsController.text.trim();

    return UserProfileModel(
      id: userProfile?.id ?? authProvider.firebaseUser!.uid,
      email: userProfile?.email ?? authProvider.firebaseUser!.email ?? '',
      role: userProfile?.role ?? UserRole.customer,
      name: userProfile?.name ?? '',
      
      height: double.tryParse(heightText),
      weight: double.tryParse(weightText),
      targetWeight: double.tryParse(targetWeightText),
      goal: double.tryParse(targetWeightText)?.toString(), // geriye uyumluluk
      healthNotes: healthNotesText.isEmpty ? null : healthNotesText,
      allergies: allergiesText.isEmpty ? null : allergiesText,
      medications: medicationsText.isEmpty ? null : medicationsText,
      
      // Koru
      phoneNumber: userProfile?.phoneNumber,
      birthDate: userProfile?.birthDate,
      gender: userProfile?.gender,
      assignedDistributorId: userProfile?.assignedDistributorId,
      profilePhotoUrl: userProfile?.profilePhotoUrl,
      distributorLevel: userProfile?.distributorLevel,
      monthlyVPTarget: userProfile?.monthlyVPTarget,
      isOnboarded: userProfile?.isOnboarded ?? false,
      age: userProfile?.age,
      programStartDate: userProfile?.programStartDate,
      userGoal: userProfile?.userGoal,
      wakeTime: userProfile?.wakeTime,
      lunchTime: userProfile?.lunchTime,
      sleepTime: userProfile?.sleepTime,
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final updatedProfile = _buildUpdatedProfile();
      final success = await authProvider.updateUserProfile(updatedProfile);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sağlık ve hedefleriniz başarıyla kaydedildi.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilgiler kaydedilemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedeflerim & Tercihler'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Boy (cm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validateHeight,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Mevcut Kilo (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validateWeight,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _targetWeightController,
                decoration: const InputDecoration(
                  labelText: 'Hedef Kilo (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validateWeight,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _healthNotesController,
                decoration: const InputDecoration(
                  labelText: 'Sağlık Durumu Notları',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 1000,
                validator: validateHealthField,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Alerji Bilgileri',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 1000,
                validator: validateHealthField,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(
                  labelText: 'İlaç Kullanımı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 1000,
                validator: validateHealthField,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
