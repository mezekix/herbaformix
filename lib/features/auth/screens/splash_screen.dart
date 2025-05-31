import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  // GoRouter'da kullanmak için rota adını tanımlıyoruz.
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Bu ekran çok basit olacak. Genellikle bir logo veya bir
    // yükleme göstergesi (CircularProgressIndicator) içerir.
    // Asıl yönlendirme işini GoRouter'ın 'redirect' mekanizması,
    // AuthProvider'ı dinleyerek yapacak. Bu yüzden burada
    // ek bir yönlendirme kodu yazmamıza gerek yok.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İsterseniz buraya uygulamanızın logosunu ekleyebilirsiniz
            // Image.asset('assets/images/herbaform_logo.png', width: 150),
            // const SizedBox(height: 30),
            Text(
              'HerbaForm',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green), // Temaya uygun renkler
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 15),
            Text('Yükleniyor...'),
          ],
        ),
      ),
    );
  }
}