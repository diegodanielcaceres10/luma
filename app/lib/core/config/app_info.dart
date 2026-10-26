/// Static app identity shared across entry points.
class AppInfo {
  AppInfo._();

  /// Display name. Every `MaterialApp` must set it as `title`: on web an empty
  /// title clears `document.title` and the browser tab shows the URL instead.
  static const name = 'Luma';
}
