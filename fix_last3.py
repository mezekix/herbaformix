import os

c_file = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(c_file, 'r', encoding='utf-8') as f:
    c_content = f.read()

avatar_def = """
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
"""

# Try to remove any existing _buildCustomerInitialsAvatar
idx = c_content.find("Widget _buildCustomerInitialsAvatar")
if idx != -1:
    end_idx = c_content.find("}", c_content.find("}", c_content.find("}", idx) + 1) + 1) + 1
    if end_idx != 0:
        c_content = c_content[:idx] + c_content[end_idx:]

while c_content.rstrip().endswith('}'):
    c_content = c_content.rstrip()[:-1]

c_content = c_content + avatar_def + '}\n'

with open(c_file, 'w', encoding='utf-8') as f:
    f.write(c_content)

h_file = 'lib/features/home/screens/home_screen.dart'
with open(h_file, 'r', encoding='utf-8') as f:
    h_content = f.read()

unused_imports = [
    "import 'package:go_router/go_router.dart';",
    "import 'package:url_launcher/url_launcher.dart';",
    "import '../../../core/avatar_color_helper.dart';",
    "import '../../../core/utils/whatsapp_helper.dart';",
    "import '../../../models/scheduled_follow_up_model.dart';",
    "import '../../../services/firestore_service.dart';",
    "import '../../customers/screens/add_edit_customer_screen.dart';",
    "import '../../customers/screens/customer_detail_screen.dart';",
    "import '../../customers/screens/customer_list_screen.dart';",
    "import '../../orders/screens/add_edit_order_screen.dart';",
    "import '../../orders/screens/order_list_screen.dart';",
    "import '../../profile/screens/profile_screen.dart';",
    "import '../widgets/vp_pulse_card.dart';",
    "import '../widgets/today_actions_strip.dart';",
    "import '../widgets/customer_pipeline_bar.dart';",
    "import '../widgets/recent_activity_feed.dart';",
    "import '../widgets/critical_actions_states.dart';"
]

for imp in unused_imports:
    h_content = h_content.replace(imp + '\n', '')
    h_content = h_content.replace(imp, '')

with open(h_file, 'w', encoding='utf-8') as f:
    f.write(h_content)
    
print("Fixed imports and braces!")
