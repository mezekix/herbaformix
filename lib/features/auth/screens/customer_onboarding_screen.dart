import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../products/providers/product_provider.dart';
import '../../program/providers/program_provider.dart';
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
  final TextEditingController _targetWeightController = TextEditingController();

  String _selectedGoal = ''; // weight_loss, healthy_living, weight_gain
  String? _selectedGender;
  TimeOfDay? _wakeTime;
  TimeOfDay? _lunchTime;
  TimeOfDay? _sleepTime;
  XFile? _selfieImage;
  final ImagePicker _picker = ImagePicker();

  void _nextPage() {
    FocusScope.of(context).unfocus();
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
    if (userProfile == null) return;

    String? fmt(TimeOfDay? t) => t == null
        ? null
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final updated = userProfile.copyWith(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      phoneNumber: _phoneController.text.trim(),
      weight: double.tryParse(_weightController.text.trim()),
      height: double.tryParse(_heightController.text.trim()),
      targetWeight: double.tryParse(_targetWeightController.text.trim()),
      userGoal: _selectedGoal,
      wakeTime: fmt(_wakeTime),
      lunchTime: fmt(_lunchTime),
      sleepTime: fmt(_sleepTime),
      gender: _selectedGender,
      isOnboarded: true,
      programStartDate: DateTime.now(),
    );

    await authProvider.updateUserProfile(updated);

    if (!mounted) return;

    // Otomatik Program Oluşturma — güncellenmiş profilden okur,
    // eski mutable kodda olduğu gibi yeni saatleri kullanır.
    final productProvider = context.read<ProductProvider>();
    final programProvider = context.read<ProgramProvider>();

    await programProvider.createAutomaticProgram(
      userId: updated.id,
      userGoal: _selectedGoal,
      currentWeight: double.tryParse(_weightController.text.trim()),
      targetWeight: double.tryParse(_targetWeightController.text.trim()),
      allProducts: productProvider.products,
      wakeTime: updated.wakeTime,
      lunchTime: updated.lunchTime,
      sleepTime: updated.sleepTime,
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Programınız Hazır! 🎉', style: TextStyle(color: AppColors.garden, fontWeight: FontWeight.bold)),
        content: const Text(
          'Program saatleriniz yaşam tarzınıza göre ayarlandı.\n\nLütfen program ekranına giderek kullanacağınız ürünleri ekleyin ve programınızı tamamlayın.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.garden,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Programıma Git', style: TextStyle(color: AppColors.white)),
          )
        ],
      ),
    );

    if (!mounted) return;
    context.goNamed('create-program'); // Program düzenleme ekranına yönlendir
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
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
                              FocusScope.of(context).unfocus();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
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
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          hint: const Text('Seçiniz'),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.garden, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                            DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                            DropdownMenuItem(value: 'Belirtmek İstemiyorum', child: Text('Belirtmek İstemiyorum')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedGender = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildNextButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
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
                    const SizedBox(height: 16),
                    _buildBMIIndicator(),
                    const SizedBox(height: 16),
                    _buildPhysicalInput('Hedef Kilo', _targetWeightController, 'kg', Icons.flag, Colors.orange.shade100),
                    if (_isAutoTargetCalculated)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0, left: 8.0),
                        child: Text(
                          'ℹ️ İdeal kilonuza göre hedef otomatik belirlendi, isterseniz değiştirebilirsiniz.',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    const Spacer(),
                    _buildNextButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
                        onChanged: (val) {
                          setState(() {});
                          if (label == 'Mevcut Kilo' || label == 'Boy') {
                            _calculateTargetWeight();
                          } else if (label == 'Hedef Kilo') {
                            _userChangedTargetWeight = true;
                          }
                        },
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

  bool _userChangedTargetWeight = false;
  bool _isAutoTargetCalculated = false;

  void _calculateTargetWeight() {
    if (_userChangedTargetWeight) return; // Kullanıcı kendisi girdiyse bozma

    final h = double.tryParse(_heightController.text.trim());
    if (h != null && h > 0) {
      // Standart BMI=22 hedefi
      final hMeters = h / 100;
      final target = 22 * hMeters * hMeters;
      _targetWeightController.text = target.toStringAsFixed(1);
      _isAutoTargetCalculated = true;
    } else {
      _isAutoTargetCalculated = false;
    }
  }

  Widget _buildBMIIndicator() {
    final w = double.tryParse(_weightController.text.trim());
    final h = double.tryParse(_heightController.text.trim());
    
    if (w == null || h == null || h <= 0) return const SizedBox.shrink();

    final bmi = w / ((h / 100) * (h / 100));
    String status = '';
    Color color = Colors.grey;

    if (bmi < 18.5) {
      status = 'Zayıf';
      color = Colors.blue;
    } else if (bmi < 25) {
      status = 'Normal';
      color = Colors.green;
    } else if (bmi < 30) {
      status = 'Fazla Kilolu';
      color = Colors.orange;
    } else {
      status = 'Obez';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart, color: color),
              const SizedBox(width: 8),
              const Text('Vücut Kitle İndeksi (BMI):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(bmi.toStringAsFixed(1), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStep5Selfie() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
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
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).unfocus();
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
                    const SizedBox(height: 24),
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
                    const Spacer(),
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
              ),
            ),
          ),
        );
      },
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
