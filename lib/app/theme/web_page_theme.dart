import 'dart:js_interop';

@JS('document.documentElement.style.setProperty')
external void _setRootStyle(JSString property, JSString value);

void updateWebPageTheme(String brightness, int background) {
  final rgb = (background & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  _setRootStyle('color-scheme'.toJS, brightness.toJS);
  _setRootStyle('--app-background'.toJS, '#$rgb'.toJS);
}
