import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/program_editor_args.dart';
import '../providers/program_provider.dart';
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
