import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/program_editor_args.dart';
import '../models/program_template_model.dart';
import '../providers/program_provider.dart';
import '../providers/program_template_provider.dart';
import '../widgets/goal_selection_step.dart';
import '../widgets/weight_input_step.dart';
import '../widgets/meal_plan_step.dart';
import '../widgets/program_summary_step.dart';

/// Müşteri program oluşturma wizard ekranı.
/// 4 adım: Hedef Seçimi → (Kilo Girişi) → Öğün Planı → Özet & Onay
/// Global ProgramProvider kullanır (main.dart'ta tanımlı).
class CreateProgramScreen extends StatefulWidget {
  static const String routeName = 'create-program';
  final ProgramEditorArgs? editorArgs;

  const CreateProgramScreen({super.key, this.editorArgs});

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndInitWizard();
  }

  Future<void> _loadProfileAndInitWizard() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final provider = context.read<ProgramProvider>();
      final authProvider = context.read<AuthProvider>();
      final firestoreService = context.read<FirestoreService>();

      String? targetUserId;
      if (widget.editorArgs?.isDistributorMode == true) {
        targetUserId = widget.editorArgs!.targetUserId;
      } else {
        targetUserId = authProvider.firebaseUser?.uid;
      }

      if (targetUserId != null && targetUserId.isNotEmpty) {
        try {
          final profile = await firestoreService.getUserProfile(targetUserId);
          if (mounted) {
            provider.initializeWizardWithProfile(profile);
          }
        } catch (e) {
          debugPrint('Profil yüklenirken hata: $e');
          if (mounted) {
            provider.resetWizard();
          }
        }
      } else {
        provider.resetWizard();
      }

      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return _CreateProgramView(editorArgs: widget.editorArgs);
  }
}

class _CreateProgramView extends StatelessWidget {
  final ProgramEditorArgs? editorArgs;

  const _CreateProgramView({this.editorArgs});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgramProvider>();
    final step = provider.currentStep;

    // Adım indeksi (ilerleme göstergesi için)
    final stepIndex = _stepIndex(step, provider.selectedGoal);
    final totalSteps = provider.selectedGoal == 'weight_loss' ? 4 : 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: stepIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.nightSky),
                onPressed: () => provider.previousStep(),
              )
            : IconButton(
                icon: const Icon(Icons.close, color: AppColors.nightSky),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          _stepTitle(step),
          style: const TextStyle(
            color: AppColors.nightSky,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: _ProgressBar(current: stepIndex + 1, total: totalSteps),
        ),
      ),
      body: Column(
        children: [
          if (editorArgs?.isDistributorMode == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Text(
                'Program yazılan müşteri: ${editorArgs!.targetCustomerName}',
                style: const TextStyle(
                  color: AppColors.nightSky,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // Şablondan başla — yalnızca distribütör modunda + ilk adımda göster
          if (editorArgs?.isDistributorMode == true &&
              step == ProgramWizardStep.goalSelection)
            _TemplateStarterBanner(
              onPick: () => _showTemplatePicker(context, provider),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildStep(context, step, provider),
            ),
          ),
        ],
      ),
    );
  }

  int _stepIndex(ProgramWizardStep step, String? goal) {
    switch (step) {
      case ProgramWizardStep.goalSelection:
        return 0;
      case ProgramWizardStep.weightInput:
        return 1;
      case ProgramWizardStep.mealPlan:
        return goal == 'weight_loss' ? 2 : 1;
      case ProgramWizardStep.summary:
        return goal == 'weight_loss' ? 3 : 2;
    }
  }

  String _stepTitle(ProgramWizardStep step) {
    switch (step) {
      case ProgramWizardStep.goalSelection:
        return 'Hedefini Seç';
      case ProgramWizardStep.weightInput:
        return 'Kilo Bilgileri';
      case ProgramWizardStep.mealPlan:
        return 'Öğün Planı';
      case ProgramWizardStep.summary:
        return 'Program Özeti';
    }
  }

  Future<void> _showTemplatePicker(
    BuildContext context,
    ProgramProvider provider,
  ) async {
    final auth = context.read<AuthProvider>();
    final distributorId = auth.firebaseUser?.uid;
    if (distributorId == null) return;

    // Şablon listesini bu distribütör için başlat (idempotent).
    context
        .read<ProgramTemplateProvider>()
        .watchForDistributor(distributorId);

    final selected = await showModalBottomSheet<ProgramTemplateModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _TemplatePickerSheet(),
    );

    if (selected != null) {
      provider.applyTemplate(selected);
    }
  }

  Widget _buildStep(
    BuildContext context,
    ProgramWizardStep step,
    ProgramProvider provider,
  ) {
    switch (step) {
      case ProgramWizardStep.goalSelection:
        return const GoalSelectionStep(key: ValueKey('goal'));
      case ProgramWizardStep.weightInput:
        return const WeightInputStep(key: ValueKey('weight'));
      case ProgramWizardStep.mealPlan:
        return const MealPlanStep(key: ValueKey('meal'));
      case ProgramWizardStep.summary:
        return ProgramSummaryStep(
          key: const ValueKey('summary'),
          editorArgs: editorArgs,
        );
    }
  }
}

/// Üst ilerleme çubuğu
class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: current / total,
      backgroundColor: Colors.grey.shade200,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 4,
    );
  }
}

/// Hedef seçimi adımının üstünde gösterilen, distribütörün şablon
/// kataloğundan başlatabileceği kısayol bandı.
class _TemplateStarterBanner extends StatelessWidget {
  final VoidCallback onPick;
  const _TemplateStarterBanner({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPick,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.10),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Şablondan Başla',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.nightSky,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kayıtlı şablon kullanarak hedef ve öğünleri otomatik doldur.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Distribütörün şablonlarını listeleyen, seçim yapılınca [ProgramTemplateModel]
/// döndüren bottom sheet.
class _TemplatePickerSheet extends StatelessWidget {
  const _TemplatePickerSheet();

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: mediaHeight * 0.75),
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'Şablon Seç',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: Consumer<ProgramTemplateProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.templates.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }
                if (provider.templates.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'Henüz Şablonun Yok',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.nightSky,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Profil > "Program Şablonlarım" üzerinden bir şablon oluşturabilirsin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: provider.templates.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final tpl = provider.templates[i];
                    final goalLabel = switch (tpl.userGoal) {
                      'weight_loss' => 'Kilo Verme',
                      'weight_gain' => 'Kilo Alma',
                      _ => 'Sağlıklı Yaşam',
                    };
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        tpl.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '$goalLabel · ${tpl.slots.length} öğün · ${tpl.defaultDurationMonths} ay',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pop(tpl),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
