import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/home/presentation/widgets/dashboard/dashboard_headers.dart';

Widget host({String? photoUrl}) {
  return MaterialApp(
    home: Scaffold(
      body: DashboardGreetingRow(
        initials: 'DC',
        firstName: 'Diego',
        photoUrl: photoUrl,
      ),
    ),
  );
}

void main() {
  group('DashboardGreetingRow', () {
    testWidgets('shows the initials and the greeting without a photo',
        (tester) async {
      await tester.pumpWidget(host());

      expect(find.text('DC'), findsOneWidget);
      expect(find.text('Hola, Diego 👋'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('requests the photo and keeps the initials until it loads',
        (tester) async {
      const url = 'https://lh3.googleusercontent.com/a/photo=s160-c';
      await tester.pumpWidget(host(photoUrl: url));

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        image.image,
        isA<NetworkImage>().having((p) => p.url, 'url', url),
      );
      expect(find.text('DC'), findsOneWidget);
    });
  });
}
