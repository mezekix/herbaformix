import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/program_template_model.dart';
import '../providers/program_template_provider.dart';
import 'edit_program_template_screen.dart';

/// Distribütörün kendi program şablonlarını listeleyip yönettiği ekran.
///
/// Listede her kart: isim, hedef etiketi, slot sayısı, son güncelleme.
/// FAB ile yeni şablon, kart tap ile düzenleme, popup menü ile silme.
class ProgramTemplatesScreen extends StatefulWidget {
  static const String routeName = 'program-templates';

  const ProgramTemplatesScreen({super.key});

  @override
  State<ProgramTemplatesScreen> createState() => _ProgramTemplatesScreenState();
}

class _ProgramTemplatesScreenState extends State<ProgramTemplatesScreen> {
  bool _watchScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_watchScheduled) return;
    _watchScheduled = true;

    // Callback çalıştığında bu sayfanın context'i route geçişi nedeniyle
    // deaktif olmuş olabilir. Gerekli bağımlılıkları context aktifken al.
    final distributorId = context.read<AuthProvider>().firebaseUser?.uid;
    final templateProvider = context.read<ProgramTemplateProvider>();
    if (distributorId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      templateProvider.watchForDistributor(distributorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Program Şablonlarım'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        onPressed: () => context.goNamed(EditProgramTemplateScreen.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Şablon'),
      ),
      body: Consumer<ProgramTemplateProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.templates.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.errorMessage != null && provider.templates.isEmpty) {
            return _ErrorState(message: provider.errorMessage!);
          }

          if (provider.templates.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: provider.templates.length,
            itemBuilder: (_, i) {
              final tpl = provider.templates[i];
              return _TemplateCard(
                template: tpl,
                onTap: () => context.goNamed(
                  EditProgramTemplateScreen.routeName,
                  extra: tpl,
                ),
                onDelete: () => _confirmDelete(tpl),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(ProgramTemplateModel template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şablonu Sil'),
        content: Text(
          '"${template.name}" şablonunu silmek istediğinden emin misin? '
          'Bu şablonu önceden kullanmış müşterilerin aktif programları etkilenmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final provider = context.read<ProgramTemplateProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.delete(template.id);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Şablon silindi.' : (provider.errorMessage ?? 'Silinemedi.'),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ProgramTemplateModel template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final goalLabel = _goalLabel(template.userGoal);
    final goalColor = _goalColor(template.userGoal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.backgroundMuted),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: goalColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.nightSky,
                        ),
                      ),
                      if ((template.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          template.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Chip(label: goalLabel, color: goalColor),
                          _Chip(
                            label: '${template.slots.length} öğün',
                            color: Colors.blueGrey,
                          ),
                          _Chip(
                            label: '${template.defaultDurationMonths} ay',
                            color: Colors.deepPurple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        title: Text('Sil'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _goalLabel(String goal) {
    switch (goal) {
      case 'weight_loss':
        return 'Kilo Verme';
      case 'weight_gain':
        return 'Kilo Alma';
      default:
        return 'Sağlıklı Yaşam';
    }
  }

  static Color _goalColor(String goal) {
    switch (goal) {
      case 'weight_loss':
        return Colors.green;
      case 'weight_gain':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textMutedLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz Şablon Yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sık kullandığın program yapılarını şablon olarak kaydet, '
              'müşterilere uygularken zaman kazan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
