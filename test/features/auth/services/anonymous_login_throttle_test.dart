import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/features/auth/services/anonymous_login_throttle.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('allows the first anonymous login attempt', () async {
    final throttle = AnonymousLoginThrottle(
      now: () => DateTime(2026, 7, 19, 12),
    );

    expect(await throttle.remainingCooldown(), isNull);
  });

  test('persists cooldown after a successful anonymous login', () async {
    var now = DateTime(2026, 7, 19, 12);
    final throttle = AnonymousLoginThrottle(now: () => now);

    await throttle.recordSuccess();
    now = now.add(const Duration(minutes: 15));

    expect(await throttle.remainingCooldown(), const Duration(minutes: 45));
  });

  test('allows another anonymous login after cooldown', () async {
    var now = DateTime(2026, 7, 19, 12);
    final throttle = AnonymousLoginThrottle(now: () => now);

    await throttle.recordSuccess();
    now = now.add(const Duration(hours: 1));

    expect(await throttle.remainingCooldown(), isNull);
  });
}
