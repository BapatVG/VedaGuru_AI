import 'dart:io';

void openWebUrl(String url) {
  try {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', url]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [url]);
    } else if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isAndroid) {
      Process.run('am', ['start', '-a', 'android.intent.action.VIEW', '-d', url]);
    }
  } catch (_) {}
}

void downloadFile(List<int> bytes, String filename) {
  try {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$filename');
    file.writeAsBytesSync(bytes);
    openWebUrl(file.path);
  } catch (_) {}
}
