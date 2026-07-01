import os

# 1. Update consultant_dashboard_view.dart
filepath = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

content = "".join(lines)

# Remove bad imports
bad_imports = [
    "import '../../../recipes/screens/recipe_list_screen.dart';",
    "import '../../../products/screens/distributor_product_usage_screen.dart';",
    "import '../../customers/screens/customer_detail_screen.dart';"
]
for imp in bad_imports:
    content = content.replace(imp, "")

# Add correct imports
correct_imports = """import '../../../products/screens/recipes_list_screen.dart';
import '../../distributor_product_usage_screen.dart';
import '../../../orders/screens/order_list_screen.dart';
import '../../../profile/screens/profile_screen.dart';
import '../../../customers/screens/customer_detail_screen.dart';
"""
if "import '../../../orders/screens/order_list_screen.dart';" not in content:
    content = correct_imports + content

# Add _riskCountFuture and didChangeDependencies
did_change = """
  Future<int>? _riskCountFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.userProfile != null && _riskCountFuture == null) {
      _riskCountFuture = context
          .read<FirestoreService>()
          .getAtRiskCustomerCount(widget.userProfile!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
"""
content = content.replace("  @override\\n  Widget build(BuildContext context) {", did_change)

# Add _buildCustomerInitialsAvatar
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
content = content.replace("\\n}\\n", avatar_code)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)


# 2. Clean up home_screen.dart
home_filepath = 'lib/features/home/screens/home_screen.dart'
with open(home_filepath, 'r', encoding='utf-8') as f:
    home_lines = f.readlines()

home_content = "".join(home_lines)

# Remove _riskCountFuture definition and logic
home_content = home_content.replace("  Future<int>? _riskCountFuture;\\n", "")

risk_logic = """    if (userProfile != null &&
        userProfile.role == UserRole.distributor &&
        _riskCountFuture == null) {
      _riskCountFuture = context
          .read<FirestoreService>()
          .getAtRiskCustomerCount(userProfile.id);
    }"""
home_content = home_content.replace(risk_logic, "")

# Remove _buildCustomerInitialsAvatar
avatar_start = home_content.find("  Widget _buildCustomerInitialsAvatar(")
if avatar_start != -1:
    avatar_end = home_content.find("  Widget _buildConsultantDashboard(", avatar_start)
    if avatar_end != -1:
        home_content = home_content[:avatar_start] + home_content[avatar_end:]

with open(home_filepath, 'w', encoding='utf-8') as f:
    f.write(home_content)

print("Consultant extraction and cleanup completed!")
