import os
import re

# Fix home_screen.dart
home_filepath = 'lib/features/home/screens/home_screen.dart'
with open(home_filepath, 'r', encoding='utf-8') as f:
    home_content = f.read()

# It literally contains \n characters because of dart string literal error. We fix it by replacing \\n with newline.
home_content = home_content.replace('\\n', '\n')

with open(home_filepath, 'w', encoding='utf-8') as f:
    f.write(home_content)

# Fix consultant_dashboard_view.dart
consultant_filepath = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(consultant_filepath, 'r', encoding='utf-8') as f:
    consultant_content = f.read()

consultant_content = consultant_content.replace(
    "import '../../distributor_product_usage_screen.dart';", 
    "import '../../../products/screens/distributor_product_usage_screen.dart';"
)

if "_showQuickAddMenu" in consultant_content:
    # Remove unused _showQuickAddMenu
    # Or actually wait, _showQuickAddMenu is used by home_screen.dart in FloatingActionButton!
    # If we extracted it into ConsultantDashboardView, it's NOT available to home_screen.dart!
    pass

with open(consultant_filepath, 'w', encoding='utf-8') as f:
    f.write(consultant_content)

print("Home screen newlines fixed!")
