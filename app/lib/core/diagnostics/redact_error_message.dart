final _uuid = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);
final _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');

/// Makes an error message safer to send off the device: ids and email
/// addresses are replaced and the text is cut at [maxLength].
///
/// This is a best-effort filter for the usual leaks, not a guarantee that the
/// message holds no personal data.
String redactErrorMessage(String message, {int maxLength = 300}) {
  final redacted =
      message.replaceAll(_uuid, '<id>').replaceAll(_email, '<email>');
  return redacted.length <= maxLength
      ? redacted
      : '${redacted.substring(0, maxLength)}…';
}
