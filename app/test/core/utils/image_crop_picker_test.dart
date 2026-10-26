import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luma/core/ai/scan_stage.dart';
import 'package:luma/core/utils/image_crop_picker.dart';
import 'package:luma/core/widgets/cropper/crop_preview_dialog.dart';

void main() {
  final cropped = Uint8List.fromList([1, 2, 3]);

  late List<String> croppedFrom;
  late List<PickedImage> processed;

  setUp(() {
    croppedFrom = [];
    processed = [];
  });

  Future<XFile?> pick(ImageSource source) async => XFile('/photos/ticket.jpg');

  Future<Uint8List?> crop(String path) async {
    croppedFrom.add(path);
    return cropped;
  }

  Future<String> process(PickedImage image, ScanProgress report) async {
    processed.add(image);
    return 'scan-result';
  }

  group('pickCroppedImage', () {
    test('returns null when the user does not pick a photo', () async {
      final result = await pickCroppedImage<String>(
        source: ImageSource.gallery,
        pick: (_) async => null,
        crop: crop,
        process: process,
      );

      expect(result, isNull);
      expect(croppedFrom, isEmpty);
      expect(processed, isEmpty);
    });

    test('returns null when the user cancels the cropper', () async {
      final result = await pickCroppedImage<String>(
        source: ImageSource.gallery,
        pick: pick,
        crop: (_) async => null,
        process: process,
      );

      expect(result, isNull);
      expect(processed, isEmpty);
    });

    test('without preview it processes the cropped image right away',
        () async {
      final result = await pickCroppedImage<String>(
        source: ImageSource.gallery,
        pick: pick,
        crop: crop,
        process: process,
      );

      expect(result, 'scan-result');
      expect(processed.single.bytes, cropped);
      expect(processed.single.mimeType, 'image/jpeg');
    });

    test('without preview a failure is thrown to the caller', () async {
      expect(
        pickCroppedImage<String>(
          source: ImageSource.gallery,
          pick: pick,
          crop: crop,
          process: (_, __) async => throw Exception('down'),
        ),
        throwsException,
      );
    });

    test('sends nothing until the preview asks for it', () async {
      final result = await pickCroppedImage<String>(
        source: ImageSource.gallery,
        pick: pick,
        crop: crop,
        process: process,
        preview: (bytes, send) async {
          expect(bytes, cropped);
          expect(processed, isEmpty);
          return (action: CropPreviewAction.cancel, value: null);
        },
      );

      expect(result, isNull);
      expect(processed, isEmpty);
    });

    test('returns what the preview got from sending', () async {
      final result = await pickCroppedImage<String>(
        source: ImageSource.gallery,
        pick: pick,
        crop: crop,
        process: process,
        preview: (bytes, send) async =>
            (action: CropPreviewAction.send, value: await send((_) {})),
      );

      expect(result, 'scan-result');
      expect(processed, hasLength(1));
    });

    test('a failed send can be retried with the same image', () async {
      var attempts = 0;

      final result = await pickCroppedImage<String>(
        source: ImageSource.gallery,
        pick: pick,
        crop: crop,
        process: (image, _) async {
          attempts++;
          if (attempts == 1) throw Exception('down');
          return 'second-try';
        },
        preview: (bytes, send) async {
          await expectLater(send((_) {}), throwsException);
          return (action: CropPreviewAction.send, value: await send((_) {}));
        },
      );

      expect(result, 'second-try');
      expect(attempts, 2);
      // The photo was cropped once: retrying does not ask for a new crop.
      expect(croppedFrom, hasLength(1));
    });

    test('passes the stages the scan reports on to the preview', () async {
      final stages = <ScanStage>[];

      final result = await pickCroppedImage<String>(
        source: ImageSource.gallery,
        pick: pick,
        crop: crop,
        process: (image, report) async {
          report(ScanStage.sending);
          report(ScanStage.processing);
          return 'scan-result';
        },
        preview: (bytes, send) async =>
            (action: CropPreviewAction.send, value: await send(stages.add)),
      );

      expect(result, 'scan-result');
      expect(stages, [ScanStage.sending, ScanStage.processing]);
    });

    test('without preview the reported stages go nowhere', () async {
      final result = await pickCroppedImage<String>(
        source: ImageSource.gallery,
        pick: pick,
        crop: crop,
        process: (image, report) async {
          report(ScanStage.sending);
          return 'scan-result';
        },
      );

      expect(result, 'scan-result');
    });

    test('crops the original photo again when the user asks to', () async {
      var reviews = 0;

      final result = await pickCroppedImage<String>(
        source: ImageSource.gallery,
        pick: pick,
        crop: crop,
        process: process,
        preview: (bytes, send) async {
          reviews++;
          if (reviews == 1) {
            return (action: CropPreviewAction.recrop, value: null);
          }
          return (action: CropPreviewAction.send, value: await send((_) {}));
        },
      );

      expect(result, 'scan-result');
      expect(croppedFrom, ['/photos/ticket.jpg', '/photos/ticket.jpg']);
      expect(processed, hasLength(1));
    });
  });
}
