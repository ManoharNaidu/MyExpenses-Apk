import os
import re

def migrate_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Replace imports
    content = content.replace("import 'package:provider/provider.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';")

    # context.watch<AuthProvider>() -> ref.watch(authProvider)
    content = re.sub(r'context\.watch<([A-Za-z0-9_]+)>()', lambda m: f"ref.watch({m.group(1).lower()[:1] + m.group(1)[1:]}Provider)", content)
    # context.read<AuthProvider>() -> ref.read(authProvider)
    content = re.sub(r'context\.read<([A-Za-z0-9_]+)>()', lambda m: f"ref.read({m.group(1).lower()[:1] + m.group(1)[1:]}Provider)", content)
    
    # Fix the duplicate 'ProviderProvider' if the class was AuthProvider
    content = content.replace('authProviderProvider', 'authProvider')
    content = content.replace('themeProviderProvider', 'themeProvider')

    if 'ref.watch(' in content or 'ref.read(' in content:
        if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in content:
            content = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + content
            
        content = content.replace('extends StatelessWidget', 'extends ConsumerWidget')
        content = content.replace('Widget build(BuildContext context)', 'Widget build(BuildContext context, WidgetRef ref)')
        
        content = content.replace('extends StatefulWidget', 'extends ConsumerStatefulWidget')
        content = re.sub(r'extends State<([A-Za-z0-9_]+)>', r'extends ConsumerState<\1>', content)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Migrated {filepath}")

for root, dirs, files in os.walk('lib'):
    # skip core providers as we will modify them manually
    if 'auth_provider.dart' in files and root.endswith('auth'):
        continue
    if 'theme_provider.dart' in files and root.endswith('theme'):
        continue
    for file in files:
        if file.endswith('.dart'):
            migrate_file(os.path.join(root, file))

print("Done")
