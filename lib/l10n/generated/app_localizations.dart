import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'HerbaForm'**
  String get appTitle;

  /// No description provided for @languageLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Varsayılanı'**
  String get languageSystem;

  /// No description provided for @languageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get languageEnglish;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get languageSettingsTitle;

  /// No description provided for @languageSettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dilini değiştir'**
  String get languageSettingsSubtitle;

  /// No description provided for @drawerHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get drawerHome;

  /// No description provided for @drawerProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profilim'**
  String get drawerProfile;

  /// No description provided for @drawerProducts.
  ///
  /// In tr, this message translates to:
  /// **'Ürünler'**
  String get drawerProducts;

  /// No description provided for @drawerProductCatalog.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Kataloğu'**
  String get drawerProductCatalog;

  /// No description provided for @drawerCustomers.
  ///
  /// In tr, this message translates to:
  /// **'Müşterilerim'**
  String get drawerCustomers;

  /// No description provided for @drawerOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerim'**
  String get drawerOrders;

  /// No description provided for @drawerOrderHistory.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Geçmişim'**
  String get drawerOrderHistory;

  /// No description provided for @drawerPersonalDevelopment.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Gelişim'**
  String get drawerPersonalDevelopment;

  /// No description provided for @drawerWaterTracker.
  ///
  /// In tr, this message translates to:
  /// **'Su Takip'**
  String get drawerWaterTracker;

  /// No description provided for @drawerCalorieTracker.
  ///
  /// In tr, this message translates to:
  /// **'Kalori Sayacı'**
  String get drawerCalorieTracker;

  /// No description provided for @drawerSignOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get drawerSignOut;

  /// No description provided for @drawerDefaultUserName.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Adı'**
  String get drawerDefaultUserName;

  /// No description provided for @drawerDefaultEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi'**
  String get drawerDefaultEmail;

  /// No description provided for @appSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama'**
  String get appSettingsTitle;

  /// No description provided for @appSettingsSecurity.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get appSettingsSecurity;

  /// No description provided for @appSettingsChangePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get appSettingsChangePassword;

  /// No description provided for @appSettingsNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get appSettingsNotifications;

  /// No description provided for @appSettingsNotificationsChecking.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol ediliyor...'**
  String get appSettingsNotificationsChecking;

  /// No description provided for @appSettingsNotificationsOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık — öğün ve su hatırlatıcıları çalışıyor'**
  String get appSettingsNotificationsOn;

  /// No description provided for @appSettingsNotificationsOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı — hatırlatıcı almıyorsun'**
  String get appSettingsNotificationsOff;

  /// No description provided for @appSettingsNotificationsEnabled.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler açıldı. ✓'**
  String get appSettingsNotificationsEnabled;

  /// No description provided for @appSettingsNotificationsDenied.
  ///
  /// In tr, this message translates to:
  /// **'İzin verilmedi. Cihaz Ayarları > Uygulamalar > Herbaformix > Bildirimler menüsünden manuel açabilirsin.'**
  String get appSettingsNotificationsDenied;

  /// No description provided for @appSettingsSendTestNotification.
  ///
  /// In tr, this message translates to:
  /// **'Test Bildirimi Gönder'**
  String get appSettingsSendTestNotification;

  /// No description provided for @appSettingsTestNotificationSent.
  ///
  /// In tr, this message translates to:
  /// **'Test bildirimi tetiklendi.'**
  String get appSettingsTestNotificationSent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
