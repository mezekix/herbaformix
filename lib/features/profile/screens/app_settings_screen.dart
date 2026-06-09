import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../program/services/notification_service.dart';
import '../widgets/change_password_dialog.dart';

class AppSettingsScreen extends StatelessWidget {
  static const String routeName = 'app-settings';

  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Güvenlik',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.primary),
              title: const Text('Şifre Değiştir', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () => ChangePasswordDialog.show(context),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Bildirimler',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: FutureBuilder<bool>(
              future: NotificationService().hasPermission(),
              builder: (context, snapshot) {
                final hasPermission = snapshot.data ?? false;
                final isLoading = snapshot.connectionState == ConnectionState.waiting;

                return ListTile(
                  leading: Icon(
                    hasPermission
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    color: hasPermission ? AppColors.primary : Colors.grey,
                  ),
                  title: const Text(
                    'Bildirimler',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isLoading
                        ? 'Kontrol ediliyor...'
                        : hasPermission
                            ? 'Açık — öğün ve su hatırlatıcıları çalışıyor'
                            : 'Kapalı — hatırlatıcı almıyorsun',
                    style: TextStyle(
                      color: hasPermission ? Colors.green.shade700 : Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: hasPermission
                      ? null
                      : () async {
                          final service = NotificationService();
                          final granted = await service.requestPermission();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                granted
                                    ? 'Bildirimler açıldı. ✓'
                                    : 'İzin verilmedi. Cihaz Ayarları > Uygulamalar > Herbaformix > Bildirimler menüsünden manuel açabilirsin.',
                              ),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        },
                );
              },
            ),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined, color: Colors.green),
              title: const Text('Test Bildirimi Gönder', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () async {
                final service = NotificationService();
                await service.showTestNotification();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test bildirimi tetiklendi.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
