/// Metadata keys where Supabase stores the Google profile photo, in order of
/// preference.
const _avatarKeys = ['avatar_url', 'picture'];

/// Google serves the photo as a small thumbnail (`=s96-c`) by default.
final _googleSizeSuffix = RegExp(r'=s\d+-c$');

/// Returns the profile photo URL stored in the Supabase user [metadata], or
/// `null` when there is no usable one, so the UI can fall back to initials.
///
/// Only `https` URLs are accepted. Google thumbnails are upsized to [size]
/// pixels so they stay sharp inside the avatar.
String? resolveAvatarUrl(Map<String, dynamic>? metadata, {int size = 160}) {
  if (metadata == null) return null;

  for (final key in _avatarKeys) {
    final value = metadata[key];
    if (value is! String) continue;

    final url = value.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) continue;

    if (uri.host.endsWith('googleusercontent.com')) {
      return url.replaceFirst(_googleSizeSuffix, '=s$size-c');
    }
    return url;
  }

  return null;
}
