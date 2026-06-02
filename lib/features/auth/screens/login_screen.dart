import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_role.dart'; // Rol modelini import et
import '../providers/auth_provider.dart';
// import 'package:go_router/go_router.dart'; // Gerekirse yönlendirme için

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isRegisterMode = false; // Giriş/Kayıt modunu takip etmek için
  bool _obscurePassword = true;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isRegisterMode) {
      // Kayıt Modu
      final inviteCode = _inviteCodeController.text.trim().isEmpty
          ? null
          : _inviteCodeController.text.trim();
      success = await authProvider.signUpWithInviteCode(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: UserRole.customer,
        inviteCode: inviteCode,
      );
    } else {
      // Giriş Modu
      success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (!success) {
        final message = authProvider.errorMessage ??
            (_isRegisterMode
                ? 'Kayıt başarısız. Lütfen tekrar deneyin.'
                : 'Giriş başarısız. E-posta veya şifre hatalı.');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } else if (_isRegisterMode) {
        // Kayıt başarılıysa kullanıcıya bilgi ver ve giriş moduna geçir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.')),
        );
        setState(() {
          _isRegisterMode = false;
        });
      }
      // Başarılı giriş durumunda go_router zaten yönlendirme yapacak.
    }
  }

  Future<void> _submitGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    String? inviteCode;
    if (_isRegisterMode) {
      inviteCode = _inviteCodeController.text.trim().isEmpty ? null : _inviteCodeController.text.trim();
    }
    
    // Google ile yeni kaydolan herkes müşteri (customer) olarak başlar.
    final success = await authProvider.signInWithGoogle(role: UserRole.customer, inviteCode: inviteCode);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (!success) {
        final message = authProvider.errorMessage ?? 'Google ile giriş iptal edildi veya başarısız oldu.';
        // Hata mesajını göstermeyebiliriz eğer kullanıcı iptal ettiyse (errorMessage null olabilir).
        if (authProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      }
      // Başarılı giriş durumunda go_router zaten yönlendirme yapacak.
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _formKey.currentState?.reset(); // Mod değiştirince formu temizle
      _inviteCodeController.clear(); // Davet kodunu temizle
    });
  }

  Future<void> _showForgotPasswordDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const _ForgotPasswordDialog(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stitch MCP style colors
    const Color stitchPrimary = AppColors.primary;
    const Color stitchBackgroundLight = Color(0xFFf7f8f6);
    const Color stitchBorder = Color(0xFFe0e3dd);
    const Color stitchTextPrimary = Color(0xFF141612);
    const Color stitchTextSecondary = Color(0xFF74816a);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF181e14) : stitchBackgroundLight;
    final cardColor = isDark ? const Color(0xFF181e14) : Colors.white;
    final inputBg = isDark ? const Color(0xFF1f261b) : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : stitchBorder;
    final textPrimary = isDark ? Colors.white : stitchTextPrimary;
    final textSecondary = isDark ? Colors.grey[400]! : stitchTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Container(
                        color: cardColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                      const SizedBox(height: 12),
                      // Logo
                      SizedBox(
                        height: 120,
                        child: Image.asset(
                          'assets/logo/logo_h.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.spa,
                              size: 80,
                              color: stitchPrimary,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Headline
                      Text(
                        _isRegisterMode ? 'Aramıza Katılın' : 'Tekrar Hoş Geldiniz',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isRegisterMode
                            ? 'Sağlıklı yaşam yolculuğunuza başlayın'
                            : 'Sağlıklı yaşam yolculuğunuza devam edin',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Email
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'E-posta veya Kullanıcı Adı',
                          hintStyle: TextStyle(color: textSecondary),
                          prefixIcon: Icon(Icons.person_outline, color: textSecondary),
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: stitchPrimary, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || !value.contains('@')) {
                            return 'Geçerli bir e-posta girin.';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Şifre',
                          hintStyle: TextStyle(color: textSecondary),
                          prefixIcon: Icon(Icons.lock_outline, color: textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: stitchPrimary, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length < 6) {
                            return 'Şifre en az 6 karakter olmalı.';
                          }
                          return null;
                        },
                      ),
                      // Davet Kodu (Sadece kayıt modunda)
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: _inviteCodeController,
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Distribütörünüzden aldığınız kod (opsiyonel)',
                              hintStyle: TextStyle(color: textSecondary),
                              prefixIcon: Icon(Icons.card_giftcard_outlined, color: textSecondary),
                              filled: true,
                              fillColor: inputBg,
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: stitchPrimary, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                      // Forgot Password Link
                      if (!_isRegisterMode) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            ),
                            child: const Text(
                              'Şifremi Unuttum?',
                              style: TextStyle(
                                color: stitchPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                      ],
                      
                      // Login Button
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(color: stitchPrimary),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: stitchPrimary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: stitchPrimary.withAlpha(64),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              _isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                      const SizedBox(height: 16),

                      // --- TEST BYPASS (sadece debug build) ---
                      if (kDebugMode) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() => _isLoading = true);
                                    final auth = Provider.of<AuthProvider>(
                                        context,
                                        listen: false);
                                    await auth.signIn(
                                        'test@test.com', '1234321');
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  },
                            icon: const Icon(Icons.bug_report_outlined,
                                size: 18),
                            label: const Text('Test Girişi (Distribütör)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade700,
                              side: BorderSide(
                                  color: Colors.orange.shade300, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Social Login Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: borderColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'veya ile devam et',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: borderColor)),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Social Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            icon: Icons.g_mobiledata, // Fallback icon since we don't have SVG
                            borderColor: borderColor,
                            bgColor: inputBg,
                            iconColor: textPrimary,
                            iconSize: 36,
                            onTap: _submitGoogleSignIn,
                          ),
                          const SizedBox(width: 24),
                          _buildSocialButton(
                            icon: Icons.apple,
                            borderColor: borderColor,
                            bgColor: inputBg,
                            iconColor: textPrimary,
                          ),
                          const SizedBox(width: 24),
                          _buildSocialButton(
                            icon: Icons.face,
                            borderColor: borderColor,
                            bgColor: inputBg,
                            iconColor: stitchPrimary,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isRegisterMode
                                ? 'Zaten bir hesabınız var mı?'
                                : 'Henüz hesabınız yok mu?',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: _toggleMode,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              _isRegisterMode ? 'Giriş Yapın' : 'Kayıt Ol',
                              style: const TextStyle(
                                color: stitchPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  ),
),
),
);
}

  Widget _buildSocialButton({
    required IconData icon,
    required Color borderColor,
    required Color bgColor,
    required Color iconColor,
    double iconSize = 24,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF181e14)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Şifre Sıfırlama'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'E-posta adresinizi girin',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Geçerli bir e-posta girin.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            Navigator.of(context).pop();

            final success = await authProvider.sendPasswordResetEmail(
              _emailController.text.trim(),
            );

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.'
                      : (authProvider.errorMessage ??
                          'Şifre sıfırlama bağlantısı gönderilemedi.'),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Gönder'),
        ),
      ],
    );
  }
}
