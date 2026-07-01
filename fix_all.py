import os

# 1. FIX HOME SCREEN
h_file = 'lib/features/home/screens/home_screen.dart'
with open(h_file, 'r', encoding='utf-8') as f:
    h_content = f.read()

# Remove any remaining _riskCountFuture references in didChangeDependencies
risk_block = """    if (userProfile != null &&
        userProfile.role == UserRole.distributor &&
        _riskCountFuture == null) {
      _riskCountFuture = context
          .read<FirestoreService>()
          .getAtRiskCustomerCount(userProfile.id);
    }"""
h_content = h_content.replace(risk_block, "")

# Ensure ConsultantDashboardView is called with the new callback
old_call = """          return _buildConsultantDashboard(
            context,
            userProfile,
            authProvider,
            orderProvider,
            customerProvider,
            productProvider,
            homeProvider,
          );"""
new_call = """          return ConsultantDashboardView(
            userProfile: userProfile,
            authProvider: authProvider,
            onNavigateToCustomers: () => setState(() => _customerNavIndex = 2),
            onShowRecentActivations: () => _showRecentActivationSheet(context, customerProvider.recentlyActivatedCustomers),
          );"""
if "return _buildConsultantDashboard(" in h_content:
    h_content = h_content.replace(old_call, new_call)
    
# Remove _buildConsultantDashboard method from home_screen since we just replaced its call
# Wait, let's just make sure it's gone
idx = h_content.find("  Widget _buildConsultantDashboard(")
if idx != -1:
    h_content = h_content[:idx]

with open(h_file, 'w', encoding='utf-8') as f:
    f.write(h_content)


# 2. FIX CONSULTANT DASHBOARD
c_file = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(c_file, 'r', encoding='utf-8') as f:
    c_content = f.read()

# Add onShowRecentActivations callback
c_content = c_content.replace("final VoidCallback onNavigateToCustomers;", "final VoidCallback onNavigateToCustomers;\n  final VoidCallback onShowRecentActivations;")
c_content = c_content.replace("required this.onNavigateToCustomers,", "required this.onNavigateToCustomers,\n    required this.onShowRecentActivations,")

# Replace call to _showRecentActivationSheet
c_content = c_content.replace("_showRecentActivationSheet(\n                    context, customerProvider.recentlyActivatedCustomers)", "widget.onShowRecentActivations()")
c_content = c_content.replace("_showRecentActivationSheet(context, customerProvider.recentlyActivatedCustomers)", "widget.onShowRecentActivations()")

# Add _buildCustomerInitialsAvatar
if "_buildCustomerInitialsAvatar" not in c_content:
    avatar_code = """
  Widget _buildCustomerInitialsAvatar(
    String firstName,
    String lastName,
    String customerId,
  ) {
    final fullName = '$firstName $lastName'.trim();
    final initials = fullName.split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bgColor = AvatarColorHelper.forUser(customerId);
    final textColor = AvatarColorHelper.textColorFor(bgColor);

    return CircleAvatar(
      radius: 24,
      backgroundColor: bgColor,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
"""
    last_brace = c_content.rfind("}")
    c_content = c_content[:last_brace] + avatar_code

# Fix imports
c_content = c_content.replace("import 'package:lucide_icons/lucide_icons.dart';", "")
c_content = c_content.replace("import '../../../products/screens/distributor_product_usage_screen.dart';", "import '../distributor_product_usage_screen.dart';")
c_content = c_content.replace("import '../../../products/screens/recipes_list_screen.dart';", "")
c_content = c_content.replace("import 'package:intl/intl.dart';", "")
c_content = c_content.replace("import '../../../../services/ai/food_estimation_service.dart';", "")
c_content = c_content.replace("import '../../../../widgets/app_drawer.dart';", "")

if "import '../../../../core/avatar_color_helper.dart';" not in c_content:
    c_content = "import '../../../../core/avatar_color_helper.dart';\n" + c_content

with open(c_file, 'w', encoding='utf-8') as f:
    f.write(c_content)

print("Done")
