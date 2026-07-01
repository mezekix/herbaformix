import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Müşteri "Destek" sekmesi — distribütöre ulaşma ve SSS
class CustomerSupportScreen extends StatelessWidget {
  final bool hideTitle;
  const CustomerSupportScreen({super.key, this.hideTitle = false});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hideTitle) ...[
              const Text(
                'Destek',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.nightSky,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sorularınız için danışmanınıza ulaşın',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Danışman iletişim kartı
            FutureBuilder<UserProfileModel?>(
              future: _getDistributorProfile(context),
              builder: (context, snapshot) {
                final distributor = snapshot.data;
                final distName = distributor?.name ?? 'Danışmanınız';
                final distPhone = distributor?.phoneNumber;

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        distName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nightSky,
                        ),
                      ),
                      if (distPhone != null && distPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          distPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Sorularınız için iletişime geçebilirsiniz',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.chat_rounded,
                              label: 'WhatsApp',
                              color: const Color(0xFF25D366),
                              onTap: () => _openWhatsApp(context, distPhone),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.phone_rounded,
                              label: 'Ara',
                              color: AppColors.primary,
                              onTap: () => _makeCall(context, distPhone),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // SSS Başlığı
            const Text(
              'Sıkça Sorulan Sorular',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
            const SizedBox(height: 12),

            _FaqItem(
              question: 'Shake\'imi ne zaman içmeliyim?',
              answer: 'Sabah kahvaltı yerine veya öğün arası olarak tüketebilirsiniz. En ideal zaman sabah saatleridir.',
            ),
            _FaqItem(
              question: 'Günde ne kadar su içmeliyim?',
              answer: 'Günde en az 2-3 litre su içmeniz önerilir. Fiziksel aktivite yaptığınız günlerde bu miktarı artırın.',
            ),
            _FaqItem(
              question: 'Ürünleri nasıl saklamalıyım?',
              answer: 'Ürünlerinizi serin, kuru ve doğrudan güneş ışığı almayan bir yerde saklayın. Açıldıktan sonra 45 gün içinde tüketin.',
            ),
            _FaqItem(
              question: 'Programıma nasıl ürün ekleyebilirim?',
              answer: 'Ana Sayfa > "Program Oluştur" butonuna tıklayarak mevcut ürünlerinizden seçim yapabilirsiniz.',
            ),
            _FaqItem(
              question: 'Kilom değişmezse ne yapmalıyım?',
              answer: 'En az 3 hafta düzenli takip yapın. Sonuçlar kişiden kişiye değişebilir. Danışmanınızla iletişime geçerek programınızı gözden geçirebilirsiniz.',
            ),
          ],
        ),
      ),
    );
  }

  Future<UserProfileModel?> _getDistributorProfile(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final distributorId = authProvider.userProfile?.assignedDistributorId;
    if (distributorId == null) return null;
    return context.read<FirestoreService>().getDistributorProfile(distributorId);
  }

  Future<void> _openWhatsApp(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Danışman telefon numarası bulunamadı.')),
        );
      }
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp açılamadı.')),
      );
    }
  }

  Future<void> _makeCall(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Danışman telefon numarası bulunamadı.')),
        );
      }
      return;
    }
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama yapılamadı.')),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.nightSky,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.answer,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey600,
                      height: 1.5,
                    ),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
