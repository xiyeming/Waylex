#!/usr/bin/env python3
"""Final visual unification: migrate remaining Divider/Card usages."""

# === settings_page.dart ===
file_path = '/home/xiyeming/Projects/RustProjects/Waylex/flutter/lib/presentation/pages/settings_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add AppDivider import
old_imports = """import '../widgets/common/app_card.dart';
import '../widgets/foundation/app_toggle.dart';"""

new_imports = """import '../widgets/common/app_card.dart';
import '../widgets/foundation/app_toggle.dart';
import '../widgets/common/app_divider.dart';"""

content = content.replace(old_imports, new_imports)

# 2. Replace Divider in shortcut items (line 346)
content = content.replace(
    "const Divider(height: 1, indent: AppTokens.space16, endIndent: AppTokens.space16)",
    "AppDivider.subtle(indent: AppTokens.space16, endIndent: AppTokens.space16)"
)

# 3. Replace Divider in language tab (line 506)
content = content.replace(
    "const Divider(height: AppTokens.space24)",
    "AppDivider.bold(height: AppTokens.space24)"
)

# 4. Replace Dividers in theme options (lines 603, 612)
content = content.replace(
    "const Divider(height: 1, indent: AppTokens.space16, endIndent: AppTokens.space16)",
    "AppDivider.subtle(indent: AppTokens.space16, endIndent: AppTokens.space16)"
)

# 5. Replace Divider before version section (line 624)
content = content.replace(
    "const Divider(height: AppTokens.space32)",
    "AppDivider.bold(height: AppTokens.space32)"
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("settings_page.dart migration complete!")

# === floating_page.dart ===
file_path = '/home/xiyeming/Projects/RustProjects/Waylex/flutter/lib/presentation/pages/floating_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add AppDivider and AppButton imports
old_imports = """import '../widgets/foundation/app_input.dart';
import '../widgets/foundation/app_button.dart';"""

new_imports = """import '../widgets/foundation/app_input.dart';
import '../widgets/foundation/app_button.dart';
import '../widgets/common/app_divider.dart';"""

content = content.replace(old_imports, new_imports)

# 2. Replace Divider(height: 1) in build method
content = content.replace(
    "const Divider(height: 1)",
    "AppDivider.subtle()"
)

# 3. Replace Card in prompt template list (line 1005)
# The Card is inside ListView.builder, wrapping a ListTile
# Replace Card( with AppCard.surface( and remove margin: EdgeInsets.zero, shape: ...
old_card = """                    return Card(
                      child: ListTile("""

new_card = """                    return AppCard.surface(
                      child: ListTile("""

content = content.replace(old_card, new_card)

# 4. Remove the margin/shape props from the Card that's now AppCard.surface
# The old Card had: margin: EdgeInsets.zero, shape: RoundedRectangleBorder(...)
# We need to find and remove these lines
content = content.replace(
    """                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius2Xl)),
                      child: Padding(
                        padding: AppTokens.cardPadding,""",
    """                      padding: AppTokens.cardPadding,"""
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("floating_page.dart migration complete!")
