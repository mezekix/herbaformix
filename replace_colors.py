import os
import re

MAPPING = {
    'Colors.grey.shade900': 'AppColors.grey900',
    'Colors.grey[900]': 'AppColors.grey900',
    'Colors.grey.shade800': 'AppColors.grey800',
    'Colors.grey[800]': 'AppColors.grey800',
    'Colors.grey.shade700': 'AppColors.grey700',
    'Colors.grey[700]': 'AppColors.grey700',
    'Colors.grey.shade600': 'AppColors.grey600',
    'Colors.grey[600]': 'AppColors.grey600',
    'Colors.grey.shade500': 'AppColors.textMuted',
    'Colors.grey[500]': 'AppColors.textMuted',
    'Colors.grey.shade400': 'AppColors.textMutedLight',
    'Colors.grey[400]': 'AppColors.textMutedLight',
    'Colors.grey.shade300': 'AppColors.textMutedLighter',
    'Colors.grey[300]': 'AppColors.textMutedLighter',
    'Colors.grey.shade200': 'AppColors.backgroundMuted',
    'Colors.grey[200]': 'AppColors.backgroundMuted',
    'Colors.grey.shade100': 'AppColors.backgroundMutedLight',
    'Colors.grey[100]': 'AppColors.backgroundMutedLight',
    'Colors.grey.shade50': 'AppColors.backgroundMutedLighter',
    'Colors.grey[50]': 'AppColors.backgroundMutedLighter',
    'Colors.grey': 'AppColors.textMuted',
}

IMPORT_STATEMENT = "import 'package:herbaformix/core/app_colors.dart';"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Sort keys by length descending to replace specific shades before plain Colors.grey
    modified_content = content
    changed = False

    for old_color, new_color in sorted(MAPPING.items(), key=lambda x: -len(x[0])):
        if old_color in modified_content:
            modified_content = modified_content.replace(old_color, new_color)
            changed = True

    if changed:
        # Check if import is already there
        if 'package:herbaformix/core/app_colors.dart' not in modified_content and 'app_colors.dart' not in modified_content:
            # Need to insert import
            # Find the last import statement
            import_indices = [m.end() for m in re.finditer(r"import\s+['\"].*?['\"];", modified_content)]
            if import_indices:
                last_import_idx = max(import_indices)
                modified_content = modified_content[:last_import_idx] + "\n" + IMPORT_STATEMENT + modified_content[last_import_idx:]
            else:
                modified_content = IMPORT_STATEMENT + "\n\n" + modified_content
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(modified_content)
        print(f"Updated {filepath}")

def main():
    lib_dir = 'lib'
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart') and file != 'app_colors.dart':
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
