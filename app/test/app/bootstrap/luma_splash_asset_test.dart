import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('luma_splash.json is a 512x512, 90 frame animation at 30 fps',
      () async {
    final data = await rootBundle.load('assets/animations/luma_splash.json');
    final composition = await LottieComposition.fromByteData(data);

    expect(composition.duration, const Duration(seconds: 3));
    expect(composition.frameRate, 30);
    expect(composition.bounds.width, 512);
    expect(composition.bounds.height, 512);
  });
}
