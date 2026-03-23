import 'dart:io';

void main() async {
  final dir = Directory('lib');
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = await entity.readAsString();
      final original = content;

      // 1. Fix createState() return type for ConsumerStatefulWidget
      content = content.replaceAllMapped(
        RegExp(r'State<([A-Za-z0-9_]+)>\s+createState\(\)'),
        (match) => 'ConsumerState<${match.group(1)}> createState()'
      );

      // 2. Fix build method in ConsumerState (remove WidgetRef ref argument)
      var parts = content.split('class ');
      for (int i = 1; i < parts.length; i++) {
        if (parts[i].contains('extends ConsumerState<')) {
          parts[i] = parts[i].replaceAll(
            'Widget build(BuildContext context, WidgetRef ref)', 
            'Widget build(BuildContext context)'
          );
        }
      }
      content = parts.join('class ');

      // 3. Fix wrong provider variable generation
      content = content.replaceAll('authProviderProvider', 'authProvider');
      content = content.replaceAll('themeProviderProvider', 'themeProvider');

      // 4. Catch any multi-line or spaced context.read / context.watch missed earlier
      content = content.replaceAllMapped(
        RegExp(r'context\s*\.\s*read\s*<\s*([A-Za-z0-9_]+)\s*>\s*\(\)'),
        (m) {
          final p = m.group(1)!;
          final camel = p.substring(0, 1).toLowerCase() + p.substring(1);
          return 'ref.read($camel)';
        }
      );
      content = content.replaceAllMapped(
        RegExp(r'context\s*\.\s*watch\s*<\s*([A-Za-z0-9_]+)\s*>\s*\(\)'),
        (m) {
          final p = m.group(1)!;
          final camel = p.substring(0, 1).toLowerCase() + p.substring(1);
          return 'ref.watch($camel)';
        }
      );

      // Check for Provider.of missed via multiline
      content = content.replaceAllMapped(
        RegExp(r'Provider\s*\.\s*of\s*<\s*([A-Za-z0-9_]+)\s*>\s*\(\s*context\s*,\s*listen\s*:\s*(true|false)\s*\)'),
        (match) {
          final p = match.group(1)!;
          final listen = match.group(2) == 'true';
          final camelP = p.substring(0, 1).toLowerCase() + p.substring(1);
          return listen ? 'ref.watch($camelP)' : 'ref.read($camelP)';
        }
      );
      
      content = content.replaceAllMapped(
        RegExp(r'Provider\s*\.\s*of\s*<\s*([A-Za-z0-9_]+)\s*>\s*\(\s*context\s*\)'),
        (match) {
          final p = match.group(1)!;
          final camelP = p.substring(0, 1).toLowerCase() + p.substring(1);
          return 'ref.watch($camelP)';
        }
      );

      if (content != original) {
        await entity.writeAsString(content);
        print('Fixed ${entity.path}');
      }
    }
  }
}
