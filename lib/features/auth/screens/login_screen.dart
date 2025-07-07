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
  bool _isLoading = false;
  bool _isRegisterMode = false; // Giriş/Kayıt modunu takip etmek için
  UserRole _selectedRole = UserRole.customer; // Varsayılan seçili rol

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
      success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole, // Seçilen rolü gönder
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
        final message = _isRegisterMode
            ? 'Kayıt başarısız. Lütfen tekrar deneyin.'
            : 'Giriş başarısız. E-posta veya şifre hatalı.';
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

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _formKey.currentState?.reset(); // Mod değiştirince formu temizle
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'ı kaldırarak daha modern bir tam ekran görünümü elde edebiliriz.
      // appBar: AppBar(title: const Text('HerbaForm Giriş')),
      body: Container(
        // 1. Adım: Gradient Arka Plan
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.rosemary, // Koyu Yeşil
              AppColors.garden, // Ana Yeşil
              AppColors.aqua, // Açık vurgu rengi
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                // 2. Adım: Yarı Saydam Kart
                elevation: 8,
                color: AppColors.white.withAlpha(230),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Logo veya Başlık
                        Image.asset(
                          'assets/logo/logo.png', // Logo yolunuzu doğrulayın
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.spa,
                              size: 60,
                              color: AppColors.primary,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegisterMode
                              ? 'Hesap Oluşturun'
                              : 'HerbaForm\'a Hoş Geldiniz',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) {
                              return 'Geçerli bir e-posta girin.';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.length < 6) {
                              return 'Şifre en az 6 karakter olmalı.';
                            }
                            return null;
                          },
                        ),
                        // Sadece kayıt modunda rol seçimini göster
                        if (_isRegisterMode) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<UserRole>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Rolünüz',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: UserRole.values.map((UserRole role) {
                              return DropdownMenuItem<UserRole>(
                                value: role,
                                child: Text(
                                  role.name,
                                ), // Extension'dan gelen isim
                              );
                            }).toList(),
                            onChanged: (UserRole? newValue) {
                              setState(() {
                                _selectedRole = newValue!;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Lütfen bir rol seçin.' : null,
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: _submitForm,
                                child: Text(
                                  _isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _toggleMode,
                                child: Text(
                                  _isRegisterMode
                                      ? 'Zaten bir hesabınız var mı? Giriş Yapın'
                                      : 'Hesabınız yok mu? Kayıt Olun',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
