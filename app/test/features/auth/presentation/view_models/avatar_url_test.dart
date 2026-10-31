import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/auth/presentation/view_models/avatar_url.dart';

const _googlePhoto = 'https://lh3.googleusercontent.com/a/ACg8ocK123';

void main() {
  group('resolveAvatarUrl', () {
    test('returns null when there is no metadata', () {
      expect(resolveAvatarUrl(null), isNull);
      expect(resolveAvatarUrl(const {}), isNull);
    });

    test('reads avatar_url', () {
      expect(
        resolveAvatarUrl({'avatar_url': 'https://example.com/me.jpg'}),
        'https://example.com/me.jpg',
      );
    });

    test('falls back to picture when avatar_url is missing', () {
      expect(
        resolveAvatarUrl({'picture': 'https://example.com/me.jpg'}),
        'https://example.com/me.jpg',
      );
    });

    test('falls back to picture when avatar_url is empty', () {
      expect(
        resolveAvatarUrl({
          'avatar_url': '  ',
          'picture': 'https://example.com/me.jpg',
        }),
        'https://example.com/me.jpg',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        resolveAvatarUrl({'avatar_url': ' https://example.com/me.jpg '}),
        'https://example.com/me.jpg',
      );
    });

    test('ignores URLs that are not https', () {
      expect(
        resolveAvatarUrl({'avatar_url': 'http://example.com/me.jpg'}),
        isNull,
      );
      expect(resolveAvatarUrl({'avatar_url': 'not a url'}), isNull);
    });

    test('ignores values that are not strings', () {
      expect(resolveAvatarUrl({'avatar_url': 42}), isNull);
      expect(resolveAvatarUrl({'avatar_url': null}), isNull);
    });

    test('upsizes the Google thumbnail', () {
      expect(
        resolveAvatarUrl({'avatar_url': '$_googlePhoto=s96-c'}),
        '$_googlePhoto=s160-c',
      );
    });

    test('uses the requested size for the Google thumbnail', () {
      expect(
        resolveAvatarUrl({'avatar_url': '$_googlePhoto=s96-c'}, size: 256),
        '$_googlePhoto=s256-c',
      );
    });

    test('keeps a Google URL without a size suffix as is', () {
      expect(
        resolveAvatarUrl({'avatar_url': _googlePhoto}),
        _googlePhoto,
      );
    });

    test('does not rewrite the size of non-Google hosts', () {
      expect(
        resolveAvatarUrl({'avatar_url': 'https://example.com/me.jpg=s96-c'}),
        'https://example.com/me.jpg=s96-c',
      );
    });
  });
}
