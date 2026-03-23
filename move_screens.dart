import 'dart:io';

void main() async {
  final screensDir = Directory('lib/screens');
  if (!await screensDir.exists()) return;

  final targetDir = Directory('lib/pages/main');

  await for (final entity in screensDir.list()) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final name = entity.uri.pathSegments.last;
      final newPath = targetDir.path + Platform.pathSeparator + name;
      
      String content = await entity.readAsString();
      // Update relative imports: ../ to ../../ since it goes from lib/screens to lib/pages/main
      content = content.replaceAll("import '../", "import '../../");
      
      await File(newPath).writeAsString(content);
      await entity.delete();
      print('Moved $name');
    }
  }

  // Update main_scaffold.dart
  final scaffoldFile = File('lib/pages/main/main_scaffold.dart');
  if (await scaffoldFile.exists()) {
    String scContent = await scaffoldFile.readAsString();
    scContent = scContent.replaceAll("import '../../screens/", "import '");
    await scaffoldFile.writeAsString(scContent);
    print('Updated main_scaffold.dart');
  }
  
  try {
     await screensDir.delete();
  } catch (e) {
     print('Could not delete screens directory');
  }
}
