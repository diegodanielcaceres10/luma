import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// The edits the user made in the crop editor, as plain values so they can be
/// sent to another isolate together with the image.
///
/// The crop rectangle is in pixels of the image after it was rotated and
/// flipped, which is how the editor reports it.
class CropJob {
  final Uint8List bytes;
  final int? cropLeft;
  final int? cropTop;
  final int? cropWidth;
  final int? cropHeight;
  final double rotationDegrees;
  final bool flipHorizontal;
  final int quality;
  final int? maxWidth;

  const CropJob({
    required this.bytes,
    this.cropLeft,
    this.cropTop,
    this.cropWidth,
    this.cropHeight,
    this.rotationDegrees = 0,
    this.flipHorizontal = false,
    this.quality = 85,
    this.maxWidth,
  });

  bool get hasCrop =>
      cropLeft != null &&
      cropTop != null &&
      cropWidth != null &&
      cropHeight != null;
}

/// Applies [job] to its image and returns the result as a JPEG. Pure and
/// synchronous: call [cropImageBytes] to run it off the UI thread.
///
/// The steps follow the order the editor previews them: EXIF orientation,
/// rotation, flip and then the crop. Metadata (EXIF, which can include the
/// location of a photo) is not kept in the result.
Uint8List cropAndEncode(CropJob job) {
  var image = img.decodeImage(job.bytes);
  if (image == null) {
    throw const FormatException('Unsupported image format');
  }

  // Photos from a camera store their rotation in EXIF; the editor shows them
  // already rotated, so the pixels have to match.
  image = img.bakeOrientation(image);

  if (job.rotationDegrees % 360 != 0) {
    image = img.copyRotate(image, angle: job.rotationDegrees);
  }
  if (job.flipHorizontal) {
    image = img.flip(image, direction: img.FlipDirection.horizontal);
  }

  if (job.hasCrop) {
    final width = job.cropWidth!;
    final height = job.cropHeight!;
    if (width < 1 || height < 1) {
      throw const FormatException('The crop area is empty');
    }
    image = img.copyCrop(
      image,
      x: job.cropLeft!,
      y: job.cropTop!,
      width: width,
      height: height,
    );
  }

  final maxWidth = job.maxWidth;
  if (maxWidth != null && image.width > maxWidth) {
    image = img.copyResize(
      image,
      width: maxWidth,
      interpolation: img.Interpolation.average,
    );
  }

  image.exif = img.ExifData();
  return img.encodeJpg(image, quality: job.quality);
}

/// Runs [cropAndEncode] in a background isolate, so cropping a large photo
/// doesn't freeze the screen.
Future<Uint8List> cropImageBytes(CropJob job) => compute(cropAndEncode, job);
