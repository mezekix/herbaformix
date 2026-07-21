import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/fcm_service.dart';
import '../../program/services/notification_service.dart';
import '../widgets/change_password_dialog.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/app_notification.dart';

class AppSettingsScreen extends StatelessWidget {
  static const String routeName = 'app-settings';

  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.userProfile;
    return Scaffold(
      appBar: AppBar(title: Text(l.appSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          _sectionLabel(l.languageLabel),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.backgroundMuted),
            ),
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: Text(
                l.languageSettingsTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_currentLanguageLabel(context, l)),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textMuted,
              ),
              onTap: () => _showLanguagePicker(context),
            ),
          ),

          const SizedBox(height: 24),

          _sectionLabel(l.appSettingsSecurity),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.backgroundMuted),
            ),
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.primary),
              title: Text(
                l.appSettingsChangePassword,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textMuted,
              ),
              onTap: () => ChangePasswordDialog.show(context),
            ),
          ),

          const SizedBox(height: 24),

          _sectionLabel(l.appSettingsNotifications),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.backgroundMuted),
            ),
            child: FutureBuilder<bool>(
              future: NotificationService().hasPermission(),
              builder: (context, snapshot) {
                final hasPermission = snapshot.data ?? false;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;

                return ListTile(
                  leading: Icon(
                    hasPermission
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    color: hasPermission
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  title: Text(
                    l.appSettingsNotifications,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isLoading
                        ? l.appSettingsNotificationsChecking
                        : hasPermission
                        ? l.appSettingsNotificationsOn
                        : l.appSettingsNotificationsOff,
                    style: TextStyle(
                      color: hasPermission
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  onTap: () async {
                    final service = NotificationService();
                    final localGranted = await service.requestPermission();
                    final fcmGranted = await FcmService().requestPermission();
                    if (fcmGranted && context.mounted) {
                      await context.read<AuthProvider>().syncFcmToken();
                    }
                    final granted = localGranted || fcmGranted;
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? l.appSettingsNotificationsEnabled
                              : l.appSettingsNotificationsDenied,
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
              side: BorderSide(color: AppColors.backgroundMuted),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.green,
              ),
              title: Text(
                l.appSettingsSendTestNotification,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textMuted,
              ),
              onTap: () async {
                final service = NotificationService();
                await service.showTestNotification();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.appSettingsTestNotificationSent)),
                );
              },
            ),
          ),
          if (profile != null) ...[
            const SizedBox(height: 24),
            _sectionLabel("Bildirim Tercihleri"),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.backgroundMuted),
              ),
              child: Column(
                children: AppNotificationType.values
                    .where(
                      (type) =>
                          type != AppNotificationType.distributorRequest &&
                          type != AppNotificationType.roleChange &&
                          (type != AppNotificationType.followUp ||
                              profile.role != UserRole.customer),
                    )
                    .map(
                      (type) => Column(
                        children: [
                          SwitchListTile(
                            title: Text('${type.label} bildirimleri'),
                            value:
                                profile.notificationSettings[type
                                    .preferenceKey] ??
                                true,
                            activeThumbColor: AppColors.primary,
                            onChanged: (value) async {
                              final settings = Map<String, bool>.from(
                                profile.notificationSettings,
                              );
                              settings[type.preferenceKey] = value;
                              await authProvider.updateUserProfile(
                                profile.copyWith(
                                  notificationSettings: settings,
                                ),
                              );
                            },
                          ),
                          if (type != AppNotificationType.values.last)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  String _currentLanguageLabel(BuildContext context, AppLocalizations l) {
    final code = context.read<LocaleProvider>().locale?.languageCode;
    return switch (code) {
      'tr' => l.languageTurkish,
      'en' => l.languageEnglish,
      _ => l.languageSystem,
    };
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final localeProvider = context.read<LocaleProvider>();
    final l = AppLocalizations.of(context);
    final current = localeProvider.locale?.languageCode;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget tile(String? value, String label) {
          final selected = value == current;
          return ListTile(
            leading: Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            title: Text(label),
            onTap: () async {
              await localeProvider.setLocale(
                value == null ? null : Locale(value),
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l.languageSettingsTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              tile(null, l.languageSystem),
              tile('tr', l.languageTurkish),
              tile('en', l.languageEnglish),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
