import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
// import '../../../services/firestore_service.dart'; // Henüz oluşturulmadı
// import '../../../models/user_profile_model.dart'; // Henüz oluşturulmadı

class ProfileScreen extends StatefulWidget {
  static const String routeName = 'profile'; // go_router için rota adı (home'un alt rotası)
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // final _formKey = GlobalKey<FormState>();
  // TextEditingController _nameController = TextEditingController();
  // TextEditingController _vpGoalController = TextEditingController();
  // String? _distributorLevel;

  // UserProfileModel? _userProfile;
  // bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // _loadUserProfile(); // Kullanıcı profilini yükle (Firestore'dan)
  }

  // Future<void> _loadUserProfile() async {
  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //   final userId = authProvider.user?.uid;
  //   if (userId != null) {
  //     // final firestoreService = Provider.of<FirestoreService>(context, listen: false);
  //     // _userProfile = await firestoreService.getUserProfile(userId);
  //     // if (_userProfile != null) {
  //     //   _nameController.text = _userProfile!.name ?? '';
  //     //   _vpGoalController.text = _userProfile!.monthlyVPTarget?.toString() ?? '';
  //     //   _distributorLevel = _userProfile!.distributorLevel;
  //     // }
  //   }
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  // Future<void> _saveProfile() async {
  //   if (!_formKey.currentState!.validate()) return;
  //   setState(() { _isLoading = true; });

  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //   final userId = authProvider.user?.uid;

  //   if (userId != null) {
  //     // final updatedProfile = UserProfileModel(
  //     //   id: userId,
  //     //   email: authProvider.user!.email!, // E-posta değişmez
  //     //   name: _nameController.text,
  //     //   distributorLevel: _distributorLevel,
  //     //   monthlyVPTarget: int.tryParse(_vpGoalController.text),
  //     // );
  //     // final firestoreService = Provider.of<FirestoreService>(context, listen: false);
  //     // await firestoreService.setUserProfile(updatedProfile);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Profil güncellendi (henüz Firestore yok)!')),
  //     );
  //   }
  //   setState(() { _isLoading = false; });
  // }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // if (_isLoading) {
    //   return Scaffold(
    //     appBar: AppBar(title: const Text('Profil')),
    //     body: const Center(child: CircularProgressIndicator()),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: /* Form(
          key: _formKey,
          child: */ Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('E-posta: ${authProvider.user?.email ?? 'N/A'}'),
              const SizedBox(height: 20),
              // TextFormField(
              //   controller: _nameController,
              //   decoration: const InputDecoration(labelText: 'Adınız Soyadınız'),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Lütfen adınızı girin.';
              //     }
              //     return null;
              //   },
              // ),
              // const SizedBox(height: 12),
              // // Distribütör Seviyesi (Basit bir Dropdown veya metin girişi olabilir MVP için)
              // TextFormField(
              //   initialValue: _distributorLevel,
              //   decoration: const InputDecoration(labelText: 'Distribütör Seviyeniz (Örn: Supervisor)'),
              //   onChanged: (value) {
              //     _distributorLevel = value;
              //   },
              // ),
              // const SizedBox(height: 12),
              // TextFormField(
              //   controller: _vpGoalController,
              //   decoration: const InputDecoration(labelText: 'Aylık VP Hedefiniz'),
              //   keyboardType: TextInputType.number,
              //   validator: (value) {
              //     if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
              //       return 'Lütfen geçerli bir sayı girin.';
              //     }
  
                  //     return null;
              //   },
              // ),
              // const SizedBox(height: 24),
              // _isLoading
              //     ? const Center(child: CircularProgressIndicator())
              //     : ElevatedButton(
              //         onPressed: _saveProfile,
              //         child: const Text('Profili Kaydet'),
              //       ),
              const Text("Profil bilgileri ve VP hedefi girişi Firestore entegrasyonu ile eklenecek."),
              const SizedBox(height: 20),
               ElevatedButton(
                onPressed: () async {
                  await authProvider.signOut();
                  if(context.mounted) {
                    // Login ekranına yönlendirme redirect ile otomatik olacak
                    // context.go(LoginScreen.routeName); // Güvenlik için, bazen redirect hemen çalışmayabilir
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ),
      // ),
    );
  }
}