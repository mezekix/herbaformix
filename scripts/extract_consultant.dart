// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final file = File('lib/features/home/screens/home_screen.dart');
  var lines = file.readAsLinesSync();

  int startIndex = -1;
  int endIndex = -1;

  // Find start of _buildConsultantDashboard
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('  Widget _buildConsultantDashboard(')) {
      startIndex = i;
      break;
    }
  }

  // Find the end of the class (the last '}')
  for (int i = lines.length - 1; i >= 0; i--) {
    if (lines[i] == '}') {
      endIndex = i - 1; // Exclude the closing brace of the HomeScreenState class
      break;
    }
  }

  if (startIndex != -1 && endIndex != -1) {
    print('Found consultant methods from line ${startIndex + 1} to ${endIndex + 1}');
    
    // Extract everything from _buildConsultantDashboard downwards
    final extractedLines = lines.sublist(startIndex, endIndex + 1);
    
    // Create new view file
    final viewFile = File('lib/features/home/screens/views/consultant_dashboard_view.dart');
    
    final viewContent = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../models/user_profile_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../orders/providers/order_provider.dart';
import '../../../customers/providers/customer_provider.dart';
import '../../../products/providers/product_provider.dart';
import '../../providers/home_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/ai/food_estimation_service.dart';
import '../../../recipes/screens/recipe_list_screen.dart';
import '../../../orders/screens/add_edit_order_screen.dart';
import '../../../customers/screens/add_edit_customer_screen.dart';
import '../../../products/screens/distributor_product_usage_screen.dart';
import '../../../../widgets/app_drawer.dart';
import '../../widgets/vp_pulse_card.dart';
import '../../widgets/today_actions_strip.dart';
import '../../widgets/customer_pipeline_bar.dart';
import '../../widgets/recent_activity_feed.dart';
import '../../../../models/scheduled_follow_up_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/critical_actions_states.dart';
import '../../../customers/screens/customer_list_screen.dart';

class ConsultantDashboardView extends StatefulWidget {
  final UserProfileModel? userProfile;
  final AuthProvider authProvider;
  final VoidCallback onNavigateToCustomers;

  const ConsultantDashboardView({
    Key? key,
    required this.userProfile,
    required this.authProvider,
    required this.onNavigateToCustomers,
  }) : super(key: key);

  @override
  State<ConsultantDashboardView> createState() => _ConsultantDashboardViewState();
}

class _ConsultantDashboardViewState extends State<ConsultantDashboardView> {
  // We can just paste the extracted methods here, but we need to remove the method signature of _buildConsultantDashboard
  // and put its body inside the build() method!

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final productProvider = context.watch<ProductProvider>();
    final homeProvider = context.watch<HomeProvider>();
    final userProfile = widget.userProfile;
    final authProvider = widget.authProvider;

    // Paste original _buildConsultantDashboard body here
    // Wait, the original _buildConsultantDashboard has its own parameters. Let's just create a dummy method for it and call it from build.
    return _buildConsultantDashboard(context, userProfile, authProvider, orderProvider, customerProvider, productProvider, homeProvider);
  }

${extractedLines.join('\\n')}
}
''';
    viewFile.writeAsStringSync(viewContent);
    print('Created consultant_dashboard_view.dart!');

    // Replace the extracted lines in home_screen.dart with a call to ConsultantDashboardView
    final newCall = '''  Widget _buildConsultantDashboard(BuildContext context, UserProfileModel? userProfile, AuthProvider authProvider, OrderProvider orderProvider, CustomerProvider customerProvider, ProductProvider productProvider, HomeProvider homeProvider) {
    return ConsultantDashboardView(
      userProfile: userProfile,
      authProvider: authProvider,
      onNavigateToCustomers: () => setState(() => _customerNavIndex = 2), // Example, update if wrong
    );
  }''';

    lines.replaceRange(startIndex, endIndex + 1, [newCall]);
    
    // Add import for the new view
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('import \'views/customer_dashboard_view.dart\';')) {
        lines.insert(i + 1, 'import \'views/consultant_dashboard_view.dart\';');
        break;
      }
    }

    file.writeAsStringSync(lines.join('\\n'));
    print('Updated home_screen.dart!');
  } else {
    print('Could not find bounds!');
  }
}
