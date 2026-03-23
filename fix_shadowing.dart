import 'dart:io';

void main() async {
  // 1. History Screen
  var hFile = File('lib/pages/main/history_screen.dart');
  if (await hFile.exists()) {
    var hContent = await hFile.readAsString();
    if (!hContent.contains('package:flutter_riverpod/flutter_riverpod.dart')) {
      hContent = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + hContent;
      await hFile.writeAsString(hContent);
      print('Fixed history_screen.dart');
    }
  }

  // 2. Auth Page
  var aFile = File('lib/pages/auth/auth_page.dart');
  if (await aFile.exists()) {
    var aContent = await aFile.readAsString();
    if (!aContent.contains('package:flutter_riverpod/flutter_riverpod.dart')) {
      aContent = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + aContent;
      await aFile.writeAsString(aContent);
      print('Fixed auth_page.dart');
    }
  }

  // 3. Main.dart
  var mFile = File('lib/main.dart');
  if (await mFile.exists()) {
    var mContent = await mFile.readAsString();
    mContent = mContent.replaceAll('final themeProvider = ref.watch(themeProvider);', 'final themeProv = ref.watch(themeProvider);');
    mContent = mContent.replaceAll('themeProvider.mode', 'themeProv.mode');
    await mFile.writeAsString(mContent);
    print('Fixed main.dart');
  }

  // 4. Settings Page
  var sFile = File('lib/pages/main/settings_page.dart');
  if (await sFile.exists()) {
    var sContent = await sFile.readAsString();
    sContent = sContent.replaceAll('final authProvider = ref.watch(authProvider);', 'final authProv = ref.watch(authProvider);');
    sContent = sContent.replaceAll('final themeProvider = ref.watch(themeProvider);', 'final themeProv = ref.watch(themeProvider);');
    await sFile.writeAsString(sContent);
    print('Fixed settings_page.dart');
  }

  // 5. Main Scaffold
  var msFile = File('lib/pages/main/main_scaffold.dart');
  if (await msFile.exists()) {
    var msContent = await msFile.readAsString();
    msContent = msContent.replaceAll('final authProvider = ref.read(authProvider);', 'final authProv = ref.read(authProvider);');
    msContent = msContent.replaceAll('authProvider.updateCurrency', 'authProv.updateCurrency');
    msContent = msContent.replaceAll('authProvider.state', 'authProv.state');
    await msFile.writeAsString(msContent);
    print('Fixed main_scaffold.dart');
  }

  print('Done');
}
