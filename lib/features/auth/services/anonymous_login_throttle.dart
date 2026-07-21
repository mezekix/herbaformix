import 'package:shared_preferences/shared_preferences.dart';

/// Limits successful anonymous-account creation attempts on this device.
///
/// The timestamp is persisted so closing/reopening the app cannot reset the
/// cooldown. This is a client-side guard; server-side Firebase quotas remain
/// the final abuse boundary.
class AnonymousLoginThrottle {
  AnonymousLoginThrottle({
    SharedPreferences? preferences,
    DateTime Function()? now,
    this.cooldown = const Duration(hours: 1),
  }) : _preferences = preferences,
       _now = now ?? DateTime.now;

  static const _lastSuccessKey = 'auth.last_anonymous_login_success_ms';

  final SharedPreferences? _preferences;
  final DateTime Function() _now;
  final Duration cooldown;

  Future<Duration?> remainingCooldown() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final lastSuccessMs = preferences.getInt(_lastSuccessKey);
    if (lastSuccessMs == null) return null;

    final elapsed = _now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastSuccessMs),
    );
    if (elapsed.isNegative) return cooldown;
    if (elapsed >= cooldown) return null;
    return cooldown - elapsed;
  }

  Future<void> recordSuccess() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setInt(_lastSuccessKey, _now().millisecondsSinceEpoch);
  }
}
