import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_profile_model.dart'; // UserProfileModel'i import et
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = 'profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _vpGoalController;
  String?
  _distributorLevel; // Bu da bir controller veya state ile yönetilebilir

  bool _isLoading = false;
  bool _isInitialized =
      false; // Verilerin AuthProvider'dan ilk kez yüklendiğini takip etmek için

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _vpGoalController = TextEditingController();
    // Verileri AuthProvider'dan almak için initState'te doğrudan erişim yerine
    // didChangeDependencies veya build metodu içinde context ile erişmek daha güvenlidir.
    // Ancak ilk değer ataması için bir kerelik bir işlem yapacağız.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AuthProvider'dan veriler yüklendiğinde controller'ları doldur.
    // Bu, ekran her açıldığında değil, bağımlılıklar değiştiğinde (ve ilk kez) çalışır.
    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(
        context,
        listen: false,
      ); // listen:false önemli
      final userProfile = authProvider.userProfile;
      if (userProfile != null) {
        _nameController.text = userProfile.name ?? '';
        _vpGoalController.text = userProfile.monthlyVPTarget?.toString() ?? '';
        _distributorLevel = userProfile.distributorLevel;
        debugPrint(
          "ProfileScreen: Veriler AuthProvider'dan yüklendi: ${userProfile.name}",
        );
      } else {
        debugPrint(
          "ProfileScreen: AuthProvider'dan profil verisi alınamadı veya null.",
        );
      }
      _isInitialized = true; // Tekrar tekrar doldurmayı önle
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // FirestoreService'i Provider'dan alabiliriz veya AuthProvider üzerinden bir metot çağırabiliriz.
    // final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final currentFirebaseUser = authProvider.firebaseUser;
    if (currentFirebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bulunamadı. Lütfen tekrar giriş yapın.'),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Mevcut profili alıp sadece değişen alanları güncellemek daha iyi olabilir,
    // ama şimdilik tümünü yeniden oluşturuyoruz.
    final updatedProfile = UserProfileModel(
      id: currentFirebaseUser.uid,
      email: currentFirebaseUser.email!, // E-posta Auth'tan gelir, değişmez.
      name: _nameController.text.trim(),
      distributorLevel:
          _distributorLevel, // Bu değerin nasıl set edildiğine dikkat edin (örn: Dropdown)
      monthlyVPTarget: int.tryParse(_vpGoalController.text.trim()),
    );

    try {
      // AuthProvider üzerinden güncelleme metodunu çağıralım
      bool success = await authProvider.updateUserProfile(updatedProfile);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil güncellenemedi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vpGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AuthProvider'ı dinleyerek _userProfile null ise yükleniyor gösterebiliriz
    // veya direkt controller'lardaki değere güvenebiliriz.
    // didChangeDependencies'de ilk yüklemeyi yaptığımız için build'de tekrar okumaya gerek yok.
    final authProvider = Provider.of<AuthProvider>(context); // Dinleme aktif

    if (authProvider.status == AuthStatus.authenticating ||
        (authProvider.status == AuthStatus.authenticated &&
            authProvider.userProfile == null &&
            !_isInitialized)) {
      // Eğer _isInitialized false ise ve userProfile null ise, hala veri bekleniyor olabilir.
      // Bu durum, _onAuthStateChanged'in asenkron çalışmasından kaynaklanabilir.
      return Scaffold(
        appBar: AppBar(title: const Text('Profilim Yükleniyor...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // authProvider.userProfile null ise ve _isInitialized true ise, bir sorun var demektir ya da yeni kullanıcıdır.
    // Bu durumu daha iyi yönetmek gerekebilir. Şimdilik form gösterilecek.

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'E-posta: ${authProvider.firebaseUser?.email ?? 'N/A'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Adınız Soyadınız',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen adınızı ve soyadınızı girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Distribütör Seviyesi için örnek bir DropdownButtonFormField
              // Gerçek seviyeleri bir listeden almalısınız.
              DropdownButtonFormField<String>(
                value: _distributorLevel,
                decoration: const InputDecoration(
                  labelText: 'Distribütör Seviyeniz',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star_border_outlined),
                ),
                items:
                    [
                          'Distribütör',
                          'Supervisor',
                          'World Team',
                          'GET Team',
                          'Millionaire Team',
                          'President\'s Team',
                        ]
                        .map(
                          (label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _distributorLevel = value;
                  });
                },
                // validator: (value) { // Opsiyonel: Gerekirse validasyon ekleyin
                //   if (value == null || value.isEmpty) {
                //     return 'Lütfen seviyenizi seçin.';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vpGoalController,
                decoration: const InputDecoration(
                  labelText: 'Aylık VP Hedefiniz',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.track_changes_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'Lütfen geçerli bir sayı girin.';
                    }
                    if (int.parse(value) < 0) {
                      return 'Hedef negatif olamaz.';
                    }
                  }
                  return null; // Boş bırakılabilir
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text('Profili Kaydet'),
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
                onPressed: () async {
                  await authProvider.signOut();
                  // Yönlendirme go_router redirect ile otomatik yapılacak
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withAlpha(204),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
