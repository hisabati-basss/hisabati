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

    # Fix 1: remove `const ` in front of `Text(` or `TextStyle(` or `Icon(` or `Container` if the line has `context.`
    # A generic approach: if a line contains `const ` and `context.`, remove `const `
    lines = content.split('\n')
    for i in range(len(lines)):
        if 'const ' in lines[i] and 'context.' in lines[i]:
            lines[i] = lines[i].replace('const ', '')
            
    content = '\n'.join(lines)
    
    # Fix 2: the Wrap missing `)`.
    # In my previous script, I replaced `Wrap(\n            alignment: WrapAlignment.spaceBetween,\n            crossAxisAlignment: WrapCrossAlignment.center,\n            runSpacing: 16,` 
    # with `SizedBox(width: double.infinity, child: Wrap(...)`
    # Let's find this specific Wrap block and ensure there's a double closing `))` at its end.
    # The wrap block is usually followed by `const SizedBox(height:` or similar.
    
    # Look for `child: Wrap(` and then the next `],\n            ),` or `],\n          ),` and replace with `],\n            )),`
    
    if "child: Wrap(" in content:
        # if not already closed by `))`:
        if ")),\n            const SizedBox(height:" not in content and ")),\n          const SizedBox(height:" not in content:
            # simple string replacement:
            content = content.replace("              ],\n            ),\n            const SizedBox", "              ],\n            )),\n            const SizedBox")
            content = content.replace("              ],\n          ),\n          const SizedBox", "              ],\n          )),\n          const SizedBox")

    # Fix other common Invalid constant values.
    # Sometimes it's `const [ ... context.textColor ... ]`
    # We can just remove `const ` in front of `[` or `BoxShadow` if `context.` is present.
    lines = content.split('\n')
    for i in range(len(lines)):
        if 'const ' in lines[i] and 'context.' in lines[i]:
            lines[i] = lines[i].replace('const ', '')
    content = '\n'.join(lines)
    
    # Fix 3: In users_screen.dart, there's `error - Too many positional arguments: 0 expected, but 2 found - lib\screens\users_screen.dart:48:11`
    # That line is `_buildTabs(isMobile),`. But I probably messed up the parentheses there.
    # Wait, the error is at line 48: `_buildTabs(isMobile),` inside Wrap! Wrap expects children, it is fine.
    # Wait, `SizedBox(width: double.infinity, child: Wrap(...)`
    # The python regex was `r'(Wrap\(\s*alignment:\s*WrapAlignment\.spaceBetween,\s*crossAxisAlignment:\s*WrapCrossAlignment\.center,\s*runSpacing:\s*16,)'` -> `r'SizedBox(width: double.infinity, child: \1'`
    # This means the string `SizedBox(width: double.infinity, child: Wrap(alignment: WrapAlignment.spaceBetween, ...` is properly formed.
    
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)

print("Syntax fix done")
