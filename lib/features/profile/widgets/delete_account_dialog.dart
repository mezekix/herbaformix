import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

/// Müşteri hesabı silme onay diyaloğu.
///
/// Friction ile yanlışlık silmeyi önler:
/// - E-posta/şifre kullanıcısı: e-posta + şifre girmeli
/// - Google kullanıcısı: e-posta yazıp "Google ile Onayla ve Sil" butonuna
///   basmalı (sonra Google hesap seçim ekranı açılır)
///
/// Kullanım:
/// ```dart
/// await DeleteAccountDialog.show(context);
/// ```
class DeleteAccountDialog extends StatefulWidget {
  final String userEmail;
  final bool isGoogleUser;

  const DeleteAccountDialog({
    super.key,
    required this.userEmail,
    required this.isGoogleUser,
  });

  /// Mevcut kullanıcının provider'ına göre diyaloğu açar.
  /// Kullanıcı oturum bilgisi yoksa snackbar ile uyarır.
  static Future<void> show(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.firebaseUser?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı e-postası bulunamadı.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final isGoogleUser = authProvider.primaryAuthProvider == 'google.com';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeleteAccountDialog(
        userEmail: email,
        isGoogleUser: isGoogleUser,
      ),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isDeleting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _confirmEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _emailMatches =>
      _confirmEmailController.text.trim().toLowerCase() ==
      widget.userEmail.toLowerCase();

  bool get _canDelete {
    if (_isDeleting || !_emailMatches) return false;
    if (widget.isGoogleUser) return true;
    return _passwordController.text.isNotEmpty;
  }

  Future<void> _onDelete() async {
    if (!_canDelete) return;
    setState(() => _isDeleting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.deleteAccount(
        currentPassword:
            widget.isGoogleUser ? null : _passwordController.text,
      );
      // Başarılıysa AuthProvider auth state'i değiştirir → router login'e atar.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.delete_forever_outlined,
              color: AppColors.error, size: 24),
          const SizedBox(width: 8),
          const Text('Hesabımı Sil'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Bu işlem geri ALINAMAZ. Profilin, sağlık verilerin, ölçümlerin, '
                'su/kalori takipleriniz ve tüm geçmiş kayıtların kalıcı olarak '
                'silinecek. Danışmanının notları ise (geçmiş görüşmeler ve '
                'takipler) onun tarafında "hesabını sildi" notuyla pasif olarak '
                'kalır.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.error,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Teyit için kendi e-postanı yaz:',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.userEmail,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmEmailController,
              enabled: !_isDeleting,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'E-postanı yaz',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // E-posta/şifre kullanıcısı → şifre alanı
            // Google kullanıcısı → bilgi metni (gerçek onay Sil butonunda)
            if (widget.isGoogleUser) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hesabını Google ile açtın. Silme butonuna basınca '
                        'Google hesap seçim ekranı açılır — orada bu hesabı '
                        'tekrar onaylaman gerekir.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Şifren:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                enabled: !_isDeleting,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Mevcut şifren',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: _canDelete ? _onDelete : null,
          icon: _isDeleting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  widget.isGoogleUser
                      ? Icons.login_outlined
                      : Icons.delete_forever_outlined,
                  size: 18,
                ),
          label: Text(
            _isDeleting
                ? 'Siliniyor...'
                : (widget.isGoogleUser
                    ? 'Google ile Onayla ve Sil'
                    : 'Hesabımı Sil'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
