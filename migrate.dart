import 'dart:io';

void main() async {
  final dir = Directory('lib');
  if (!await dir.exists()) {
    print('lib folder not found');
    return;
  }

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      if (entity.path.contains('auth_provider.dart') || entity.path.contains('theme_provider.dart')) {
        continue;
      }

      String content = await entity.readAsString();
      final originalContent = content;

      if (!content.contains('Provider') && !content.contains('context.read') && !content.contains('context.watch')) {
        continue;
      }

      content = content.replaceAll(
          "import 'package:provider/provider.dart';", 
          "import 'package:flutter_riverpod/flutter_riverpod.dart';");

      content = content.replaceAllMapped(
        RegExp(r'context\.watch<([A-Za-z0-9_]+)>\(\)'),
        (match) {
          final p = match.group(1)!;
          final camelP = p.substring(0, 1).toLowerCase() + p.substring(1);
          return 'ref.watch(${camelP}Provider)';
        }
      );

      content = content.replaceAllMapped(
        RegExp(r'context\.read<([A-Za-z0-9_]+)>\(\)'),
        (match) {
          final p = match.group(1)!;
          final camelP = p.substring(0, 1).toLowerCase() + p.substring(1);
          return 'ref.read(${camelP}Provider)';
        }
      );

      content = content.replaceAllMapped(
        RegExp(r'Provider\.of<([A-Za-z0-9_]+)>\(context,\s*listen:\s*(true|false)\)'),
        (match) {
          final p = match.group(1)!;
          final listen = match.group(2) == 'true';
          final camelP = p.substring(0, 1).toLowerCase() + p.substring(1);
          return listen ? 'ref.watch(${camelP}Provider)' : 'ref.read(${camelP}Provider)';
        }
      );

      if (content.contains('ref.watch(') || content.contains('ref.read(')) {
        if (!content.contains("import 'package:flutter_riverpod/flutter_riverpod.dart';")) {
          // Find last import to place it nicely
          content = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + content;
        }

        content = content.replaceAll('extends StatelessWidget', 'extends ConsumerWidget');
        content = content.replaceAll('Widget build(BuildContext context)', 'Widget build(BuildContext context, WidgetRef ref)');
        
        content = content.replaceAll('extends StatefulWidget', 'extends ConsumerStatefulWidget');
        content = content.replaceAllMapped(
          RegExp(r'extends State<([A-Za-z0-9_]+)>'),
          (match) => 'extends ConsumerState<${match.group(1)}>'
        );
      }

      if (content != originalContent) {
        await entity.writeAsString(content);
        print('Migrated ${entity.path}');
      }
    }
  }
}
