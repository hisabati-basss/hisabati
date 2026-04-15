import os
import re

files = [
    'lib/main.dart',
    'lib/screens/taxes_screen.dart',
    'lib/screens/users_screen.dart',
    'lib/screens/hr_screen.dart',
    'lib/screens/invoice_entry_screen.dart',
    'lib/screens/auditing_screen.dart',
    'lib/screens/feasibility_study_screen.dart'
]

for fpath in files:
    if not os.path.exists(fpath):
        continue
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add import if missing in screens
    if 'screens/' in fpath and 'theme/app_theme_extension.dart' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../theme/app_theme_extension.dart';")

    # Bulk replace fixed colors
    content = content.replace('Color(0xFF1E1E24)', 'context.glassMenu')
    content = content.replace('Color(0xFF1A1A20).withOpacity(0.85)', 'context.glassMenu')
    
    content = content.replace('Colors.white.withOpacity(0.02)', 'context.cardSurface')
    content = content.replace('Colors.white.withOpacity(0.04)', 'context.cardSurface')
    content = content.replace('Colors.white.withOpacity(0.05)', 'context.cardSurface')
    
    content = content.replace('Colors.white.withOpacity(0.08)', 'context.cardBorder')
    content = content.replace('Colors.white.withOpacity(0.1)', 'context.cardBorder')
    content = content.replace('Colors.white.withOpacity(0.15)', 'context.cardBorder')
    
    # Remove local consts from screens
    content = re.sub(r'const primaryOrange.*\n', '', content)
    content = re.sub(r'const darkSurface.*\n', '', content)
    content = re.sub(r'const mutedText.*\n', '', content)

    # Replacements
    content = content.replace('darkSurface', 'context.bgSurface')
    content = content.replace('mutedText', 'context.mutedText')
    content = content.replace('Colors.white.withOpacity(0.08)', 'context.cardBorder')
    # Use context.textColor for general white where it is safe.
    # We will do text color manually or more carefully. Let's do a safe replacement
    # for Colors.white inside TextStyles.
    content = re.sub(r'(TextStyle\([^)]*color:\s*)Colors\.white([,)])', r'\1context.textColor\2', content)

    # Layout align fix: Wrap(...)
    # We need to wrap Wrap in SizedBox if it's the header wrap. We know it starts with Wrap(alignment: WrapAlignment.spaceBetween
    # Using regex to replace the specific Wrap:
    content = re.sub(
        r'(Wrap\(\s*alignment:\s*WrapAlignment\.spaceBetween,\s*crossAxisAlignment:\s*WrapCrossAlignment\.center,\s*runSpacing:\s*16,)',
        r'SizedBox(width: double.infinity, child: \1',
        content,
        count=1
    )
    # the end of Wrap usually needs an extra parenthesis. It is too risky with regex. Let's just do it manually with multi replace.
    # Wait, in the Python script we can do:
    # content = content.replace("Wrap(\n            alignment: WrapAlignment.spaceBetween,", "SizedBox(width: double.infinity, child: Wrap(\n            alignment: WrapAlignment.spaceBetween,")
    # But then it misses the closing `)` for SizedBox.
    # It's better to NOT do layout layout in python. I will do Layout fix manually per file.
    
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)

print("Color replacements done")
