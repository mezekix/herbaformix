import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/invite_status.dart';
import '../../../models/user_profile_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Müşterinin bağlı olduğu distribütörün bilgilerini salt okunur kart içinde gösterir.
///
/// - [assignedDistributorId] doluysa Firestore'dan distribütör adı ve telefonunu yükler.
/// - [assignedDistributorId] boşsa davet kodu giriş alanı gösterir.
/// - Yükleme sırasında [CircularProgressIndicator] gösterir.
/// - Hata durumunda "Distribütör bilgisi yüklenemedi." mesajı gösterir.
class DistributorInfoCard extends StatefulWidget {
  final String? assignedDistributorId;

  const DistributorInfoCard({
    super.key,
    required this.assignedDistributorId,
  });

  @override
  State<DistributorInfoCard> createState() => _DistributorInfoCardState();
}

class _DistributorInfoCardState extends State<DistributorInfoCard> {
  final _codeController = TextEditingController();
  bool _isRedeeming = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Müşterinin girdiği davet kodunu doğrular ve bağlama işlemini gerçekleştirir.
  Future<void> _redeemInviteCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Lütfen bir davet kodu girin.');
      return;
    }

    setState(() {
      _isRedeeming = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final firestoreService = context.read<FirestoreService>();
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.firebaseUser?.uid;
      final userProfile = authProvider.userProfile;

      if (uid == null || userProfile == null) {
        setState(() => _errorMessage = 'Kullanıcı oturumu bulunamadı.');
        return;
      }

      // 1. Kodu doğrula
      final inviteCode = await firestoreService.validateInviteCode(code);
      if (inviteCode == null) {
        setState(() => _errorMessage = 'Geçersiz davet kodu. Lütfen kontrol edip tekrar deneyin.');
        return;
      }

      // Süresi dolmuş mu kontrol et
      if (inviteCode.effectiveStatus == InviteStatus.expired) {
        setState(() => _errorMessage = 'Bu davet kodunun süresi dolmuş. Danışmanınızdan yeni bir kod isteyin.');
        return;
      }

      // Zaten kullanılmış mı kontrol et
      if (inviteCode.effectiveStatus == InviteStatus.used || inviteCode.isUsed) {
        setState(() => _errorMessage = 'Bu davet kodu daha önce kullanılmış.');
        return;
      }

      // 2. Profili güncelle: assignedDistributorId ekle
      final updatedProfile = userProfile.copyWith(
        assignedDistributorId: inviteCode.distributorId,
      );

      // 3. Atomik batch: profil güncelle + davet kodunu "used" yap + CRM bağla
      await firestoreService.signUpWithInviteCodeBatch(
        userProfile: updatedProfile,
        inviteCode: inviteCode,
        newUserId: uid,
        existingUser: true,
      );

      // 4. AuthProvider'daki profili yenile
      await authProvider.refreshProfile();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        setState(() => _errorMessage = message);
      }
    } finally {
      if (mounted) {
        setState(() => _isRedeeming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer distribütör zaten atanmışsa, bilgi kartını göster
    if (widget.assignedDistributorId != null &&
        widget.assignedDistributorId!.isNotEmpty) {
      return _AssignedDistributorView(
        distributorId: widget.assignedDistributorId!,
      );
    }

    // Distribütör atanmamışsa, davet kodu giriş alanını göster
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Danışmanıma Bağlan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Danışmanınızdan aldığınız davet kodunu girerek bağlanabilirsiniz.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),

            // Davet kodu giriş alanı
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'ABCD1234',
                hintStyle: TextStyle(
                  color: AppColors.textMutedLight,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                  fontSize: 20,
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              enabled: !_isRedeeming,
              onSubmitted: (_) => _redeemInviteCode(),
            ),
            const SizedBox(height: 12),

            // Hata mesajı
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Başarı mesajı
            if (_successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Bağlan butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRedeeming ? null : _redeemInviteCode,
                icon: _isRedeeming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.link),
                label: Text(
                  _isRedeeming ? 'Bağlanıyor...' : 'Davet Koduyla Bağlan',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zaten bir distribütöre bağlı olan müşteri için bilgi kartı.
///
/// Distribütör profili (örn. distribütör hesabı silinmiş, izin hatası, ya da
/// distribütör müşteri kaydını silip `assignedDistributorId` temizliği henüz
/// müşteriye yansımamışsa) yüklenemediğinde **"Bağlantıyı Kaldır ve Yeniden
/// Bağlan"** kurtarma butonu gösterir. Buton, müşterinin profilindeki
/// `assignedDistributorId` alanını siler ve profili yeniler — sonuçta üst
/// widget davet kodu giriş formunu otomatik gösterir.
class _AssignedDistributorView extends StatefulWidget {
  final String distributorId;

  const _AssignedDistributorView({required this.distributorId});

  @override
  State<_AssignedDistributorView> createState() =>
      _AssignedDistributorViewState();
}

class _AssignedDistributorViewState extends State<_AssignedDistributorView> {
  bool _isDisconnecting = false;

  Future<void> _disconnectAndRefresh() async {
    final authProvider = context.read<AuthProvider>();
    final firestoreService = context.read<FirestoreService>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) return;

    setState(() => _isDisconnecting = true);
    try {
      await firestoreService.disconnectDistributor(uid);
      await authProvider.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı kaldırıldı. Yeni bir davet kodu girebilirsiniz.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bağlantı kaldırılamadı: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDisconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return FutureBuilder<UserProfileModel?>(
      future: firestoreService.getDistributorProfile(widget.distributorId),
      builder: (context, snapshot) {
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Danışmanım',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildContent(context, snapshot),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<UserProfileModel?> snapshot,
  ) {
    // Yükleme durumu
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Hata veya bulunamadı → kurtarma yolunu göster
    if (snapshot.hasError || snapshot.data == null) {
      return _buildUnavailableState(context);
    }

    // Distribütör bilgilerini salt okunur olarak göster
    final distributor = snapshot.data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReadOnlyField(
          icon: Icons.person_outline,
          label: 'Ad Soyad',
          value: distributor.name ?? '-',
        ),
        const SizedBox(height: 10),
        _ReadOnlyField(
          icon: Icons.phone_outlined,
          label: 'Telefon',
          value: distributor.phoneNumber ?? '-',
        ),
      ],
    );
  }

  Widget _buildUnavailableState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  color: Colors.orange.shade800, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Danışman bilgisine ulaşılamıyor. Bağlantın kaldırılmış '
                  'olabilir. Yeni bir davet kodu girmek için aşağıdaki '
                  'butonu kullanabilirsin.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isDisconnecting ? null : _disconnectAndRefresh,
            icon: _isDisconnecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.link_off),
            label: Text(
              _isDisconnecting
                  ? 'Kaldırılıyor...'
                  : 'Bağlantıyı Kaldır ve Yeniden Bağlan',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Salt okunur etiket + değer çifti widget'ı.
class _ReadOnlyField extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _ReadOnlyField({
    this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
