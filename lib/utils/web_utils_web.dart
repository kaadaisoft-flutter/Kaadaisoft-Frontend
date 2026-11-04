// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void notifyFirstFrame() {
  try {
    html.window.dispatchEvent(html.CustomEvent('flutter-first-frame'));
  } catch (_) {}
}
