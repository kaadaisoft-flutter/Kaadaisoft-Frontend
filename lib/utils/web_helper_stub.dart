class Blob {
  Blob(List<dynamic> bytes, [String? type]);
}

class Url {
  static String createObjectUrlFromBlob(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  String? href;
  String? download;
  AnchorElement({this.href});
  void setAttribute(String name, String value) {}
  void click() {}
}

class _Window {
  void open(String url, String target) {}
}

final window = _Window();

