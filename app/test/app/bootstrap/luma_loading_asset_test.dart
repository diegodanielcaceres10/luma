import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('luma_loading.json is a valid 300x300, 144 frame animation at 60 fps (2.4s loop)',
      () async {
    final data = await rootBundle.load('assets/animations/luma_loading.json');
    final composition = await LottieComposition.fromByteData(data);

    expect(composition.duration, const Duration(milliseconds: 2400));
    expect(composition.frameRate, 60);
    expect(composition.bounds.width, 300);
    expect(composition.bounds.height, 300);
    expect(composition.layers.length, greaterThanOrEqualTo(8));
  });
}
