import 'dart:io';

void main() {
  final file = File('lib/features/home/screens/views/consultant_dashboard_view.dart');
  var content = file.readAsStringSync();

  // Fix broken string
  content = content.replaceAll(
    "\\nMüsait olduğunda kısaca konuşabilir miyiz?';",
    "\\n\"Müsait olduğunda kısaca konuşabilir miyiz?\";", 
    // Wait, the original was: final message = '\$greeting\\nMüsait...';
    // Let me just replace the whole method!
  );

  final originalString = "final message = '\$greeting\\nMüsait olduğunda kısaca konuşabilir miyiz?';";
  final fixedString = "final message = '\$greeting\\nMüsait olduğunda kısaca konuşabilir miyiz?';"; // Wait, in dart if it's on two lines, it's syntax error.
  
  content = content.replaceAll(
    "final message = '\$greeting\\n", 
    "final message = '\$greeting\\\\n"
  );
  
  content = content.replaceAll(
    "Müsait olduğunda kısaca konuşabilir miyiz?';",
    "Müsait olduğunda kısaca konuşabilir miyiz?';"
  );
  
  // It's easier to just do it via list of lines:
  var lines = content.split('\\n');
  for (int i=0; i<lines.length; i++) {
    if (lines[i].contains("Müsait olduğunda kısaca konuşabilir miyiz?';")) {
      lines[i-1] = "${lines[i-1].replaceAll("'\$greeting", "'\$greeting\\\\n")}Müsait olduğunda kısaca konuşabilir miyiz?';";
      lines[i] = ""; // remove the broken line
    }
  }
  
  content = lines.join('\\n');

  // Fix imports
  content = content.replaceAll(
    "import '../../../../core/theme/app_colors.dart';",
    "import '../../../../core/app_colors.dart';"
  );
  content = content.replaceAll(
    "import '../../../../core/constants/app_constants.dart';",
    "import '../../../../core/avatar_color_helper.dart';"
  );

  if (!content.contains("import 'package:go_router/go_router.dart';")) {
    content = "import 'package:go_router/go_router.dart';\\n$content";
  }
  if (!content.contains("import 'package:intl/intl.dart';")) {
    content = "import 'package:intl/intl.dart';\\n$content";
  }
  if (!content.contains("import '../../../../models/customer_model.dart';")) {
    content = "import '../../../../models/customer_model.dart';\\n$content";
  }
  if (!content.contains("import '../../customers/screens/customer_detail_screen.dart';")) {
    content = "import '../../customers/screens/customer_detail_screen.dart';\\n$content";
  }

  file.writeAsStringSync(content);
  print('Fixed consultant_dashboard_view.dart!');
}
