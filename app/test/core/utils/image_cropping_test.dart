import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:luma/core/utils/image_cropping.dart';

void main() {
  // 40x20 image: red left half, blue right half.
  img.Image buildSource() {
    final image = img.Image(width: 40, height: 20);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (x < 20) {
          image.setPixelRgb(x, y, 255, 0, 0);
        } else {
          image.setPixelRgb(x, y, 0, 0, 255);
        }
      }
    }
    return image;
  }

  Uint8List pngBytes() => img.encodePng(buildSource());

  img.Image decode(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    expect(image, isNotNull);
    return image!;
  }

  bool isRed(img.Image image, int x, int y) {
    final p = image.getPixel(x, y);
    return p.r > 150 && p.b < 100;
  }

  bool isBlue(img.Image image, int x, int y) {
    final p = image.getPixel(x, y);
    return p.b > 150 && p.r < 100;
  }

  group('cropAndEncode', () {
    test('returns a JPEG of the same size when nothing was edited', () {
      final result = cropAndEncode(CropJob(bytes: pngBytes()));

      // JPEG magic number.
      expect(result[0], 0xFF);
      expect(result[1], 0xD8);
      final image = decode(result);
      expect(image.width, 40);
      expect(image.height, 20);
    });

    test('keeps only the crop area', () {
      final result = cropAndEncode(CropJob(
        bytes: pngBytes(),
        cropLeft: 0,
        cropTop: 0,
        cropWidth: 20,
        cropHeight: 20,
      ));

      final image = decode(result);
      expect(image.width, 20);
      expect(image.height, 20);
      expect(isRed(image, 10, 10), isTrue);
    });

    test('rotates a quarter turn before cropping', () {
      final result = cropAndEncode(CropJob(
        bytes: pngBytes(),
        rotationDegrees: 90,
      ));

      final image = decode(result);
      expect(image.width, 20);
      expect(image.height, 40);
    });

    test('flips horizontally', () {
      final result = cropAndEncode(CropJob(
        bytes: pngBytes(),
        flipHorizontal: true,
      ));

      final image = decode(result);
      expect(isBlue(image, 5, 10), isTrue);
      expect(isRed(image, 35, 10), isTrue);
    });

    test('applies the EXIF orientation of camera photos', () {
      final source = buildSource();
      source.exif.imageIfd.orientation = 6;
      final jpeg = img.encodeJpg(source);

      final result = cropAndEncode(CropJob(bytes: jpeg));

      final image = decode(result);
      expect(image.width, 20);
      expect(image.height, 40);
    });

    test('does not keep metadata', () {
      final source = buildSource();
      source.exif.imageIfd.orientation = 6;
      final jpeg = img.encodeJpg(source);

      final result = cropAndEncode(CropJob(bytes: jpeg));

      expect(decode(result).exif.imageIfd.hasOrientation, isFalse);
    });

    test('limits the width keeping the proportions', () {
      final result = cropAndEncode(CropJob(
        bytes: pngBytes(),
        maxWidth: 20,
      ));

      final image = decode(result);
      expect(image.width, 20);
      expect(image.height, 10);
    });

    test('does not enlarge images narrower than the max width', () {
      final result = cropAndEncode(CropJob(
        bytes: pngBytes(),
        maxWidth: 100,
      ));

      expect(decode(result).width, 40);
    });

    test('throws when the bytes are not an image', () {
      expect(
        () => cropAndEncode(CropJob(bytes: Uint8List.fromList([1, 2, 3]))),
        throwsFormatException,
      );
    });

    test('throws when the crop area is empty', () {
      expect(
        () => cropAndEncode(CropJob(
          bytes: pngBytes(),
          cropLeft: 0,
          cropTop: 0,
          cropWidth: 0,
          cropHeight: 10,
        )),
        throwsFormatException,
      );
    });
  });
}
