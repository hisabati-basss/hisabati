import 'dart:isolate';

void main() async {
  var uri = await Isolate.resolvePackageUri(Uri.parse('package:desktop_webview_auth/desktop_webview_auth.dart'));
  print(uri);
}
