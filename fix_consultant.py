import os

filepath = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Fix the broken multiline string
for i in range(len(lines)):
    if "Müsait olduğunda kısaca konuşabilir miyiz?';" in lines[i]:
        # We know the previous line is "final message = '$greeting"
        if i > 0 and "final message = '$greeting" in lines[i-1]:
            lines[i-1] = lines[i-1].rstrip() + "\\nMüsait olduğunda kısaca konuşabilir miyiz?';\n"
            lines[i] = ""

content = "".join(lines)

# Fix imports
content = content.replace("import '../../../../core/theme/app_colors.dart';", "import '../../../../core/app_colors.dart';")
content = content.replace("import '../../../../core/constants/app_constants.dart';", "import '../../../../core/avatar_color_helper.dart';")

if "import 'package:go_router/go_router.dart';" not in content:
    content = "import 'package:go_router/go_router.dart';\n" + content
if "import 'package:intl/intl.dart';" not in content:
    content = "import 'package:intl/intl.dart';\n" + content
if "import '../../../../models/customer_model.dart';" not in content:
    content = "import '../../../../models/customer_model.dart';\n" + content
if "import '../../customers/screens/customer_detail_screen.dart';" not in content:
    content = "import '../../customers/screens/customer_detail_screen.dart';\n" + content

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed with Python!")
