import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

/// Şifre değiştirme diyalogu.
///
/// Mevcut şifre, yeni şifre ve yeni şifre tekrarı alanlarını içerir.
/// Validasyonlar:
/// - Yeni şifre ≥ 6 karakter (Gereksinim 7.4)
/// - Yeni şifre ile tekrar alanı eşleşmeli (Gereksinim 7.3)
///
/// Başarıda SnackBar gösterir ve diyalogu kapatır (Gereksinim 7.6).
/// Hata durumlarında diyalogu açık tutar (Gereksinim 7.7, 7.8, 7.9).
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  /// Şifre değiştirme diyalogunu gösterir.
  ///
  /// Gereksinim 7.2: "Şifre Değiştir" butonuna basıldığında bu metot çağrılır.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  bool _isLoading = false;

  /// Mevcut şifre alanı altında gösterilecek hata mesajı.
  /// Gereksinim 7.7: "wrong-password" hatası için.
  String? _currentPasswordError;

  /// Genel hata mesajı (requires-recent-login ve diğer hatalar için).
  /// Gereksinim 7.8, 7.9
  String? _generalError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Hata mesajlarını temizle
    setState(() {
      _currentPasswordError = null;
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Gereksinim 7.5: AuthProvider.changePassword() çağır
      await authProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      // Gereksinim 7.6: Başarıda SnackBar göster ve diyalogu kapat
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreniz başarıyla değiştirildi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        _isLoading = false;

        // Gereksinim 7.7: Mevcut şifre yanlışsa alan altında hata göster
        if (message == 'Mevcut şifreniz hatalı.') {
          _currentPasswordError = message;
        } else {
          // Gereksinim 7.8: requires-recent-login hatası
          // Gereksinim 7.9: Diğer hatalar (ağ hatası vb.)
          _generalError = message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Şifre Değiştir'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mevcut şifre alanı
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_currentPasswordVisible,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _currentPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(
                      () => _currentPasswordVisible = !_currentPasswordVisible,
                    ),
                    tooltip: _currentPasswordVisible
                        ? 'Şifreyi gizle'
                        : 'Şifreyi göster',
                  ),
                  // Gereksinim 7.7: Mevcut şifre alanı altında hata mesajı
                  errorText: _currentPasswordError,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mevcut şifrenizi girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Yeni şifre alanı
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_newPasswordVisible,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _newPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(
                      () => _newPasswordVisible = !_newPasswordVisible,
                    ),
                    tooltip: _newPasswordVisible
                        ? 'Şifreyi gizle'
                        : 'Şifreyi göster',
                  ),
                ),
                // Gereksinim 7.4: Yeni şifre ≥ 6 karakter
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yeni şifrenizi girin.';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Yeni şifre tekrarı alanı
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre Tekrarı',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(
                      () =>
                          _confirmPasswordVisible = !_confirmPasswordVisible,
                    ),
                    tooltip: _confirmPasswordVisible
                        ? 'Şifreyi gizle'
                        : 'Şifreyi göster',
                  ),
                ),
                // Gereksinim 7.3: Yeni şifre ile tekrar alanı eşleşmeli
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yeni şifrenizi tekrar girin.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Şifreler eşleşmiyor.';
                  }
                  return null;
                },
              ),

              // Gereksinim 7.8, 7.9: Genel hata mesajı
              if (_generalError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _generalError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        // İptal butonu — diyalogu kapatır
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),

        // Onay butonu — loading state'de devre dışı + CircularProgressIndicator
        // Gereksinim 7.5 (loading state)
        _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ElevatedButton(
                onPressed: _submit,
                child: const Text('Değiştir'),
              ),
      ],
    );
  }
}
