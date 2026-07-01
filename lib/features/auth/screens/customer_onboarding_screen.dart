import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../services/fcm_service.dart';
import '../../program/services/notification_service.dart';
import '../providers/auth_provider.dart';

class CustomerOnboardingScreen extends StatefulWidget {
  static const String routeName = 'customer-onboarding';
  
  const CustomerOnboardingScreen({super.key});

  @override
  State<CustomerOnboardingScreen> createState() => _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends State<CustomerOnboardingScreen> {
  // BMI eşik sabitleri (Magic Number kontrolü)
  static const double _underweightBmiLimit = 18.5;
  static const double _normalBmiLimit = 25.0;
  static const double _overweightBmiLimit = 30.0;
  static const double _maxIdealBmi = 24.9;

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
  final TextEditingController _birthDateController = TextEditingController();

  DateTime? _selectedBirthDate;
  String _selectedGoal = ''; // weight_loss, healthy_living, weight_gain, skin_care
  String? _selectedGender;
  TimeOfDay? _wakeTime;
  TimeOfDay? _lunchTime;
  TimeOfDay? _sleepTime;
  XFile? _selfieImage;
  final ImagePicker _picker = ImagePicker();

  double _heightValue = 170.0;
  double _weightValue = 70.0;
  final bool _isMetric = true;

  @override
  void initState() {
    super.initState();
    _heightController.text = _heightValue.toStringAsFixed(0);
    _weightController.text = _weightValue.toStringAsFixed(1);
    _calculateTargetWeight();
  }

  void _syncControllers() {
    if (_isMetric) {
      _heightController.text = _heightValue.toStringAsFixed(0);
      _weightController.text = _weightValue.toStringAsFixed(1);
    } else {
      _heightController.text = (_heightValue * 2.54).toStringAsFixed(0);
      _weightController.text = (_weightValue * 0.453592).toStringAsFixed(1);
    }
    _calculateTargetWeight();
  }

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

    final rawTarget = double.tryParse(_targetWeightController.text.trim());
    final targetWeightToSave = rawTarget == null
        ? null
        : (_isMetric ? rawTarget : rawTarget * 0.453592);

    int? calculatedAge;
    if (_selectedBirthDate != null) {
      final now = DateTime.now();
      calculatedAge = now.year - _selectedBirthDate!.year;
      if (now.month < _selectedBirthDate!.month || (now.month == _selectedBirthDate!.month && now.day < _selectedBirthDate!.day)) {
        calculatedAge--;
      }
    }

    final updated = userProfile.copyWith(
      name: _nameController.text.trim(),
      age: calculatedAge,
      birthDate: _selectedBirthDate,
      phoneNumber: _phoneController.text.trim(),
      weight: double.tryParse(_weightController.text.trim()),
      height: double.tryParse(_heightController.text.trim()),
      targetWeight: targetWeightToSave,
      userGoal: _selectedGoal,
      wakeTime: fmt(_wakeTime),
      lunchTime: fmt(_lunchTime),
      sleepTime: fmt(_sleepTime),
      gender: _selectedGender,
      isOnboarded: false, // İlk kayıtta yönlendirmeyi önlemek için false tutulur
    );

    await authProvider.updateUserProfile(updated);

    if (!mounted) return;

    // Bildirim izni — rationale önce, sonra OS dialog'u.
    // Onboarding tek seferlik olduğundan kullanıcı bu akışı sadece bir kez görür.
    // iOS'ta sistem izin dialog'u ömür boyu yalnız bir kez gösterildiği için
    // önce bağlamı açıklamak izin verme oranını ciddi şekilde artırır.
    final shouldAsk = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hatırlatıcıları Aç',
                style: TextStyle(
                  color: AppColors.garden,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Programının çalışması için öğün ve su zamanlarında sana bildirim '
          'göndereceğim. Bildirimler kapalıysa hatırlatma alamazsın.\n\n'
          'Şimdi açmak ister misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Şimdi Değil'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    );

    if (shouldAsk == true && mounted) {
      // OS dialog'unu tetikle. Sonuç ne olursa olsun akışı kesmiyoruz —
      // izin verilmezse kullanıcı sonradan Profil > Ayarlar > Bildirimler'den
      // tekrar açabilir.
      // 1) Lokal bildirim (öğün/su hatırlatıcı) izni — mevcut servis.
      await NotificationService().requestPermission();
      // 2) FCM (push) izni + token kaydı. iOS'ta APNs entitlement'ları için
      // ayrı bir çağrı gerekiyor; Android 13+'ta ikinci kez sorulmaz.
      final fcmGranted = await FcmService().requestPermission();
      if (fcmGranted && mounted) {
        await context.read<AuthProvider>().syncFcmToken();
      }
    }

    if (!mounted) return;

    // Program oluşturma kararı — müşteriye sor, otomatik üretme.
    // Eskiden createAutomaticProgram ile boş slot iskeleti otomatik
    // yazılıyordu; ama "saçma otomatik program" hissi veriyordu çünkü
    // kullanıcıdan onay alınmıyordu. Şimdi açık tercih:
    final createNow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Profilin Hazır! ✨',
          style: TextStyle(
            color: AppColors.garden,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Şimdi sana özel beslenme programını oluşturalım mı?\n\n'
          'Programı oluştururken kullanacağın ürünleri seçecek, '
          'öğün saatlerini ayarlayacaksın. Dilersen sonra "Programım" '
          'sekmesinden de başlayabilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Daha Sonra'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Primary color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Şimdi Oluştur'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    // Tüm işlemler tamamlandıktan sonra kullanıcının onboarding'i bitirdiği kaydedilir.
    // Bu sayede router yönlendirmesi dialoglar kapandıktan sonra tetiklenir.
    final finalProfile = updated.copyWith(isOnboarded: true);
    await authProvider.updateUserProfile(finalProfile);

    if (!mounted) return;

    if (createNow == true) {
      // Müşteri kabul etti → program oluşturma sihirbazına yönlendir.
      context.goNamed('create-program');
    } else {
      // Müşteri "Daha Sonra" dedi → ana sayfaya git + bilgi snackbar.
      context.goNamed('home');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Programını dilediğin zaman "Programım" sekmesinden '
            'oluşturabilirsin. 🌱',
          ),
          backgroundColor: AppColors.garden,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
    _birthDateController.dispose();
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
                            tooltip: 'Önceki adım',
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
                        child: const Text('Atla', style: TextStyle(color: AppColors.textMuted)),
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
                    _buildStep0GenderSelection(),
                    _buildStep4PhysicalInfo(), // Boy ve Kilo Girişi (Adım 2)
                    _buildStep1Goals(),
                    _buildStep3PersonalInfo(),
                    _buildStep5Selfie(),
                  ],
                ),
              ),
              // Bottom Button (Tüm cihazlarda aynı, sabit konumda ve boyutta)
              _buildSharedBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentPage + 1) / _totalPages;
    final percent = (progress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adım ${_currentPage + 1}/$_totalPages',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.backgroundMuted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  width: MediaQuery.of(context).size.width *
                         progress * 0.85,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 100);
    final DateTime lastDate = DateTime(now.year - 12);
    final DateTime initialDate = _selectedBirthDate ?? DateTime(now.year - 25);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.nightSky,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
      });
    }
  }

  Widget _buildDatePickerField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectBirthDate(context),
          child: AbsorbPointer(
            child: Semantics(
              label: label,
              textField: true,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.backgroundMuted),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.backgroundMuted),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.garden, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ],
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
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sana en iyi programı hazırlayabilmemiz için seni biraz tanıyalım.',
                      style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField('Adın Soyadın', _nameController, TextInputType.name, 'Örn: Elif Yılmaz'),
                    const SizedBox(height: 16),
                    _buildTextField('Telefon', _phoneController, TextInputType.phone, '05XX...'),
                    const SizedBox(height: 16),
                    _buildDatePickerField('Doğum Tarihin', _birthDateController, 'Gün.Ay.Yıl Seçin'),
                    const SizedBox(height: 8),
                    Text(
                      '* Doğum tarihiniz, BMI (Vücut Kitle Endeksi) hesaplamasında ve yaşa özel ideal kilo aralığınızı belirlemek için kullanılacaktır.',
                      style: TextStyle(fontSize: 12, color: AppColors.grey600, fontStyle: FontStyle.italic),
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

  Widget _buildStep1Goals() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ekran yüksekliğine göre kart yüksekliği dinamik ölçeklenir
        final double cardHeight = ((constraints.maxHeight - 200) / 2).clamp(130.0, 180.0);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hedefin Ne? 🎯',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sana özel yol haritanı çizmek için odaklanmak istediğin alanı seç.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grid using Rows and Columns instead of GridView to support IntrinsicHeight
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: cardHeight,
                                child: _buildGoalCard(
                                  'Kilo Vermek', '🍜',
                                  const Color(0xFFE8F5E9), const Color(0xFFB9E4C9),
                                  'weight_loss',
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SizedBox(
                                height: cardHeight,
                                child: _buildGoalCard(
                                  'Sağlıklı ve Dengeli\nYaşamak', '💧',
                                  const Color(0xFFE0F7FA), const Color(0xFFB2EBF2),
                                  'healthy_living',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: cardHeight,
                                child: _buildGoalCard(
                                  'Kilo Almak ve\nGüçlenmek', '🏋️',
                                  const Color(0xFFFFF3E0), const Color(0xFFFFE0B2),
                                  'weight_gain',
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SizedBox(
                                height: cardHeight,
                                child: _buildGoalCard(
                                  'Cilt & Kişisel\nBakım', '✨',
                                  const Color(0xFFFCE4EC), const Color(0xFFF8BBD0),
                                  'skin_care',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildStep0GenderSelection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Kart yüksekliği toplam alanın %42'si olacak şekilde dinamik olarak ölçeklenir.
        // Bu sayede küçük ve orta ekranlarda taşma yaşanmaz.
        final double cardHeight = (constraints.maxHeight * 0.42).clamp(200.0, 340.0);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Başlık bölümü
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      children: [
                        Text(
                          'Senin Yolculuğun,\nSenin Seçimin.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vücut yapınıza en uygun programı hazırlamak için başlayalım.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // İmmersive Kart Seçimleri (Yatay yan yana yerleşim)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // ── Erkek Kartı ──
                        Expanded(
                          child: SizedBox(
                            height: cardHeight,
                            child: _buildGenderCard(
                              label: 'Erkek',
                              value: 'Erkek',
                              icon: Icons.male,
                              imagePath: 'assets/images/onboarding/male_athlete.jpg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // ── Kadın Kartı ──
                        Expanded(
                          child: SizedBox(
                            height: cardHeight,
                            child: _buildGenderCard(
                              label: 'Kadın',
                              value: 'Kadın',
                              icon: Icons.female,
                              imagePath: 'assets/images/onboarding/female_athlete.jpg',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderCard({
    required String label,
    required String value,
    required IconData icon,
    required String imagePath,
  }) {
    final bool isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Arka plan görseli
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
            // Seçili ise yeşil overlay
            if (isSelected)
              Container(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            // Alt gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Color(0xCC000000),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Alt bilgi: Kategori etiketi + İsim + İkon (Yatay tasarım için optimize edilmiş boyutlar)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Text(
                            label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              height: 1.1,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            
            // Yeşil çerçeve overlay'i (köşelerde ve kenarlarda tam görünmesi için en üstte)
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: isSelected ? 4 : 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(
    String title,
    String emoji,
    Color gradientStart,
    Color gradientEnd,
    String goalValue,
  ) {
    final bool isSelected = _selectedGoal == goalValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = goalValue;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Büyük emoji
              Expanded(
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Başlık
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nightSky.withValues(alpha: 0.85),
                  height: 1.2,
                ),
              ),
              // Seçili işareti — başlık altında
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ] else
                const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 4 — Fiziksel Bilgiler (Boy ve Kilo Girişi - Ruler Style) ────
  Widget _buildStep4PhysicalInfo() {
    final double minH = _isMetric ? 100 : 40;
    final double maxH = _isMetric ? 220 : 90;
    final double stepH = 1.0;
    final String unitH = _isMetric ? 'cm' : 'in';

    final double minW = _isMetric ? 30.0 : 60.0;
    final double maxW = _isMetric ? 200.0 : 440.0;
    final double stepW = _isMetric ? 0.5 : 1.0;
    final String unitW = _isMetric ? 'kg' : 'lbs';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Headline
                    const Text(
                      'Vücut Ölçüleri',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Doğru planı oluşturmak için boy ve kilonuza ihtiyacımız var.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Height Ruler section
                    Column(
                      children: [
                        Text(
                          'BOY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _heightValue.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.nightSky,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              unitH,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RulerPicker(
                          minValue: minH,
                          maxValue: maxH,
                          initialValue: _heightValue,
                          unit: unitH,
                          step: stepH,
                          onChanged: (val) {
                            setState(() {
                              _heightValue = val;
                              _syncControllers();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Divider(color: AppColors.backgroundMuted, height: 1),
                    const SizedBox(height: 6),

                    // Weight Ruler section
                    Column(
                      children: [
                        Text(
                          'KİLO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _weightValue.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.nightSky,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              unitW,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RulerPicker(
                          minValue: minW,
                          maxValue: maxW,
                          initialValue: _weightValue,
                          unit: unitW,
                          step: stepW,
                          onChanged: (val) {
                            setState(() {
                              _weightValue = val;
                              _syncControllers();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildBMIIndicator(),
                    const SizedBox(height: 8),
                    _buildTargetWeightInput(),

                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _calculateTargetWeight() {
    final hCm = _isMetric ? _heightValue : _heightValue * 2.54;
    if (hCm > 0) {
      final hMeters = hCm / 100;
      final targetKg = _maxIdealBmi * hMeters * hMeters;
      
      if (_isMetric) {
        _targetWeightController.text = targetKg.toStringAsFixed(1);
      } else {
        // Convert kg to lbs
        final targetLbs = targetKg * 2.20462;
        _targetWeightController.text = targetLbs.toStringAsFixed(0);
      }
    }
  }

  Widget _buildBMIIndicator() {
    final hCm = _isMetric ? _heightValue : _heightValue * 2.54;
    final wKg = _isMetric ? _weightValue : _weightValue * 0.453592;
    
    if (hCm <= 0 || wKg <= 0) return const SizedBox.shrink();

    final bmi = wKg / ((hCm / 100) * (hCm / 100));
    String status = '';
    Color color = AppColors.textMuted;

    if (bmi < _underweightBmiLimit) {
      status = 'Zayıf';
      color = Colors.blue;
    } else if (bmi < _normalBmiLimit) {
      status = 'Normal';
      color = Colors.green;
    } else if (bmi < _overweightBmiLimit) {
      status = 'Fazla Kilolu';
      color = Colors.orange;
    } else {
      status = 'Obez';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Icon(Icons.monitor_heart, color: color, size: 20),
              const SizedBox(width: 8),
              const Text('Vücut Kitle İndeksi (BMI):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(bmi.toStringAsFixed(1), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTargetWeightInput() {
    final String unitW = _isMetric ? 'kg' : 'lbs';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.flag, color: Colors.black54, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HEDEF KİLO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _targetWeightController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.nightSky),
                        decoration: const InputDecoration(
                          hintText: '00.0',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Text(
                      unitW,
                      style: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.bold),
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
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                        children: [
                          TextSpan(text: 'Zaman içindeki değişimi ve gelişimi görmek ister misin? Motivasyon için ilk gün fotoğrafını çek. '),
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
                                      final image = await _picker.pickImage(
                                        source: ImageSource.camera,
                                        imageQuality: 80,
                                        maxWidth: 1080,
                                        maxHeight: 1080,
                                      );
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
                                      final image = await _picker.pickImage(
                                        source: ImageSource.gallery,
                                        imageQuality: 80,
                                        maxWidth: 1080,
                                        maxHeight: 1080,
                                      );
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
                            color: AppColors.backgroundMutedLight,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AppColors.textMutedLighter, width: 2, style: BorderStyle.solid),
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
                                    const Text('Fotoğraf Çek', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted)),
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
                                  TextSpan(text: 'sana özel hazırlanan programın', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: ' başlayacak. Hazır mısın?'),
                                ],
                              ),
                            ),
                          ),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          textField: true,
          child: TextField(
            controller: controller,
            keyboardType: type,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.backgroundMuted),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.backgroundMuted),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.garden, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedBottomButton() {
    String buttonText = 'Devam Et';
    IconData? buttonIcon = Icons.arrow_forward;
    VoidCallback? onPressed;

    if (_currentPage == 0) {
      buttonText = 'HEDEFE İLERLE';
      buttonIcon = Icons.bolt;
      onPressed = _selectedGender != null ? _nextPage : null;
    } else if (_currentPage == 1) {
      buttonText = 'Devam Et';
      buttonIcon = Icons.arrow_forward;
      onPressed = _nextPage;
    } else if (_currentPage == 2) {
      buttonText = 'Devam Et';
      buttonIcon = Icons.arrow_forward;
      onPressed = _selectedGoal.isNotEmpty ? _nextPage : null;
    } else if (_currentPage == 3) {
      buttonText = 'Devam Et';
      buttonIcon = Icons.arrow_forward;
      onPressed = _nextPage;
    } else if (_currentPage == 4) {
      buttonText = 'Yolculuğum Başlıyor 🚀';
      buttonIcon = null;
      onPressed = _finishOnboarding;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.textMutedLighter,
            foregroundColor: Colors.white,
            disabledForegroundColor: AppColors.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: onPressed != null ? 4 : 0,
            shadowColor: AppColors.primary.withValues(alpha: 0.25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (buttonIcon != null) ...[
                const SizedBox(width: 8),
                Icon(buttonIcon, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RULER PICKER WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class RulerPicker extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double initialValue;
  final String unit;
  final double step;
  final ValueChanged<double> onChanged;

  const RulerPicker({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.unit,
    required this.onChanged,
    this.step = 1.0,
  });

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late final ScrollController _scrollController;
  late double _currentValue;
  final double _itemWidth = 16.0; // Tick spacing

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    final initialOffset = ((widget.initialValue - widget.minValue) / widget.step) * _itemWidth;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final index = (offset / _itemWidth).round();
    final itemCount = ((widget.maxValue - widget.minValue) / widget.step).round();
    final clampedIndex = index.clamp(0, itemCount);
    final newValue = widget.minValue + (clampedIndex * widget.step);
    
    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });
      widget.onChanged(newValue);
    }
  }

  @override
  void didUpdateWidget(covariant RulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minValue != widget.minValue ||
        oldWidget.maxValue != widget.maxValue ||
        widget.initialValue != _currentValue ||
        oldWidget.unit != widget.unit) {
      _currentValue = widget.initialValue;
      final initialOffset = ((widget.initialValue - widget.minValue) / widget.step) * _itemWidth;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(initialOffset);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = ((widget.maxValue - widget.minValue) / widget.step).round() + 1;
    
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerPadding = constraints.maxWidth / 2;
          
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ruler Ticks list
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    final offset = _scrollController.offset;
                    final index = (offset / _itemWidth).round();
                    final targetOffset = index * _itemWidth;
                    
                    if ((offset - targetOffset).abs() > 0.1) {
                      Future.microtask(() {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            targetOffset,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: centerPadding - (_itemWidth / 2)),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    final value = widget.minValue + (index * widget.step);
                    final isMajor = (value % (widget.unit == 'cm' || widget.unit == 'in' ? 5 : 5.0) == 0);
                    
                    return SizedBox(
                      width: _itemWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: isMajor ? 2.0 : 1.0,
                            height: isMajor ? 32.0 : 18.0,
                            decoration: BoxDecoration(
                              color: isMajor ? AppColors.textMutedLight : AppColors.textMutedLighter,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Fade Gradients
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 64,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 64,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
              // Center Indicator
              Container(
                width: 3.0,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
