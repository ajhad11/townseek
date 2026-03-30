// web_stub.dart
// A stub to provide empty implementations for platform-specific plugins on web.

Future<dynamic> getApplicationDocumentsDirectory() async {
  throw UnimplementedError('getApplicationDocumentsDirectory is not supported on web.');
}

class AnchorElement {
  String? href;
  String? download;
  AnchorElement({this.href});
  void setAttribute(String name, String value) {}
  void click() {}
}

// Support for package:web migration
class HTMLAnchorElement {
  String? href;
  String? download;
  void click() {}
}

class _Document {
  const _Document();
  dynamic createElement(String tag) {
    if (tag == 'a') return HTMLAnchorElement();
    return null;
  }
}

const document = _Document();

class File {
  final String path;
  File(this.path);
  Future<void> writeAsBytes(List<int> bytes) async {}
}
