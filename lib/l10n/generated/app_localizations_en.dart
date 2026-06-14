// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HerbaForm';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System Default';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get languageSettingsSubtitle => 'Change the app language';

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerProfile => 'My Profile';

  @override
  String get drawerProducts => 'Products';

  @override
  String get drawerProductCatalog => 'Product Catalog';

  @override
  String get drawerCustomers => 'My Customers';

  @override
  String get drawerOrders => 'My Orders';

  @override
  String get drawerOrderHistory => 'Order History';

  @override
  String get drawerPersonalDevelopment => 'Personal Development';

  @override
  String get drawerWaterTracker => 'Water Tracker';

  @override
  String get drawerCalorieTracker => 'Calorie Counter';

  @override
  String get drawerSignOut => 'Sign Out';

  @override
  String get drawerDefaultUserName => 'User Name';

  @override
  String get drawerDefaultEmail => 'Email address';

  @override
  String get appSettingsTitle => 'App';

  @override
  String get appSettingsSecurity => 'Security';

  @override
  String get appSettingsChangePassword => 'Change Password';

  @override
  String get appSettingsNotifications => 'Notifications';

  @override
  String get appSettingsNotificationsChecking => 'Checking...';

  @override
  String get appSettingsNotificationsOn =>
      'On — meal and water reminders are active';

  @override
  String get appSettingsNotificationsOff =>
      'Off — you won\'t receive reminders';

  @override
  String get appSettingsNotificationsEnabled => 'Notifications enabled. ✓';

  @override
  String get appSettingsNotificationsDenied =>
      'Permission denied. You can enable them from Device Settings > Apps > Herbaformix > Notifications.';

  @override
  String get appSettingsSendTestNotification => 'Send Test Notification';

  @override
  String get appSettingsTestNotificationSent => 'Test notification triggered.';
}
