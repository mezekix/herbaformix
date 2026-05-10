import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../home/screens/home_screen.dart'; // Yönlendirme için
import '../providers/auth_provider.dart';

class CustomerOnboardingScreen extends StatefulWidget {
  static const String routeName = 'customer-onboarding';
  
  const CustomerOnboardingScreen({super.key});

  @override
  State<CustomerOnboardingScreen> createState() => _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends State<CustomerOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String _selectedGoal = ''; // weight_loss, healthy_living, weight_gain
  TimeOfDay? _wakeTime;
  TimeOfDay? _lunchTime;
  TimeOfDay? _sleepTime;
  XFile? _selfieImage;
  final ImagePicker _picker = ImagePicker();

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final authProvider = context.read<AuthProvider>();
    final userProfile = authProvider.userProfile;

    if (userProfile != null) {
      userProfile.name = _nameController.text.trim();
      userProfile.age = int.tryParse(_ageController.text.trim());
      userProfile.phoneNumber = _phoneController.text.trim();
      userProfile.weight = double.tryParse(_weightController.text.trim());
      userProfile.height = double.tryParse(_heightController.text.trim());
      userProfile.userGoal = _selectedGoal;
      userProfile.wakeTime = _wakeTime != null ? '${_wakeTime!.hour.toString().padLeft(2, '0')}:${_wakeTime!.minute.toString().padLeft(2, '0')}' : null;
      userProfile.lunchTime = _lunchTime != null ? '${_lunchTime!.hour.toString().padLeft(2, '0')}:${_lunchTime!.minute.toString().padLeft(2, '0')}' : null;
      userProfile.sleepTime = _sleepTime != null ? '${_sleepTime!.hour.toString().padLeft(2, '0')}:${_sleepTime!.minute.toString().padLeft(2, '0')}' : null;
      userProfile.isOnboarded = true;
      userProfile.programStartDate = DateTime.now();

      await authProvider.updateUserProfile(userProfile);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yolculuğunuz Başladı! 30 Günlük sayaç aktif.'),
        backgroundColor: AppColors.garden,
      ),
    );
    context.goNamed(HomeScreen.routeName);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), AppColors.white], // Soft yeşil -> beyaz
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              _buildProgressBar(),
              
              // App Bar / Geri Dön Butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _currentPage > 0
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.nightSky),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                          )
                        : const SizedBox(width: 48), // Geri butonu yoksa yer tutucu
                    if (_currentPage < _totalPages - 1)
                      TextButton(
                        onPressed: _nextPage,
                        child: const Text('Atla', style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              ),
              
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Sadece butonlarla geçiş
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildStep1Goals(),
                    _buildStep2LifestyleHours(),
                    _buildStep3PersonalInfo(),
                    _buildStep4PhysicalInfo(),
                    _buildStep5Selfie(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              width: MediaQuery.of(context).size.width * 
                     ((_currentPage + 1) / _totalPages) * 0.85, // 0.85 margin payı
              decoration: BoxDecoration(
                color: AppColors.garden,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3PersonalInfo() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tanışalım 👋',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.nightSky),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sana en iyi programı hazırlayabilmemiz için seni biraz tanıyalım.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildTextField('Adın Soyadın', _nameController, TextInputType.name, 'Örn: Elif Yılmaz'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Yaşın', _ageController, TextInputType.number, '28')),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Telefon', _phoneController, TextInputType.phone, '05XX...')),
            ],
          ),
          const Spacer(),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildStep1Goals() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hedefin Ne? 🎯',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.nightSky),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sana özel yol haritanı çizmek için odaklanmak istediğin alanı seç.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildGoalCard('Kilo Vermek', '🥗', Colors.green.shade100, 'weight_loss'),
                const SizedBox(height: 16),
                _buildGoalCard('Sağlıklı ve Dengeli Yaşamak', '🥑', Colors.blue.shade100, 'healthy_living'),
                const SizedBox(height: 16),
                _buildGoalCard('Kilo Almak ve Güçlenmek', '💪', Colors.orange.shade100, 'weight_gain'),
              ],
            ),
          ),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildStep2LifestyleHours() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Günlük Rutinin ⏰',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.nightSky),
          ),
          const SizedBox(height: 8),
          const Text(
            'Programını sana göre ayarlayabilmemiz için temel saatlerini paylaşır mısın?',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildTimePickerRow('Uyanma Saatin', _wakeTime, (time) => setState(() => _wakeTime = time)),
          const SizedBox(height: 24),
          _buildTimePickerRow('Öğle Yemeği Saatin', _lunchTime, (time) => setState(() => _lunchTime = time)),
          const SizedBox(height: 24),
          _buildTimePickerRow('Uyuma Saatin', _sleepTime, (time) => setState(() => _sleepTime = time)),
          const Spacer(),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildTimePickerRow(String label, TimeOfDay? selectedTime, Function(TimeOfDay) onSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.nightSky)),
          TextButton.icon(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
              );
              if (time != null) {
                onSelected(time);
              }
            },
            icon: const Icon(Icons.access_time, color: AppColors.garden),
            label: Text(
              selectedTime != null ? '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}' : 'Seçiniz',
              style: const TextStyle(fontSize: 16, color: AppColors.garden, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String title, String emoji, Color bgColor, String goalValue) {
    final bool isSelected = _selectedGoal == goalValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = goalValue;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.garden.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.garden : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.nightSky),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Icon(Icons.check_circle, color: AppColors.garden, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4PhysicalInfo() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Mevcut Durum ⚖️',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.nightSky),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 16, color: Colors.grey),
              children: [
                TextSpan(text: 'Gelişimini doğru takip edebilmemiz için başlangıç ölçülerini girebilirsin. '),
                TextSpan(text: '(Opsiyonel)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildPhysicalInput('Mevcut Kilo', _weightController, 'kg', Icons.monitor_weight, Colors.green.shade100),
          const SizedBox(height: 16),
          _buildPhysicalInput('Boy', _heightController, 'cm', Icons.height, Colors.blue.shade100),
          const Spacer(),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildPhysicalInput(String label, TextEditingController controller, String unit, IconData icon, Color iconBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.nightSky),
                        decoration: const InputDecoration(
                          hintText: '00.0',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(unit, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Selfie() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Başlangıç Fotoğrafı 📸',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.nightSky),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 16, color: Colors.grey),
              children: [
                TextSpan(text: '30 gün sonra farkı görmek ister misin? Motivasyon için ilk gün fotoğrafını çek. '),
                TextSpan(text: '(Zorunlu değil)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Kamera ile Çek'),
                            onTap: () async {
                              Navigator.pop(context);
                              final image = await _picker.pickImage(source: ImageSource.camera);
                              if (image != null) {
                                setState(() {
                                  _selfieImage = image;
                                });
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Galeriden Seç'),
                            onTap: () async {
                              Navigator.pop(context);
                              final image = await _picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  _selfieImage = image;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                    image: _selfieImage != null
                        ? DecorationImage(
                            image: FileImage(File(_selfieImage!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selfieImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                              ]),
                              child: const Icon(Icons.photo_camera, color: AppColors.garden, size: 32),
                            ),
                            const SizedBox(height: 16),
                            const Text('Fotoğraf Çek', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              children: [
                const Text('⏳', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                      children: const [
                        TextSpan(text: 'Butona tıkladığında '),
                        TextSpan(text: '30 Günlük', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' geri sayımın başlayacak. Hazır mısın?'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _finishOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.nightSky,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Yolculuğum Başlıyor 🚀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.garden, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _nextPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.garden,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Devam Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: AppColors.white, size: 20),
        ],
      ),
    );
  }
}
