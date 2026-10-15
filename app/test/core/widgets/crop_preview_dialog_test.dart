import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/widgets/crop_preview_dialog.dart';

void main() {
  // A valid 1x1 PNG, so the preview has a real image to show.
  final bytes = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA'
      'hKmMIQAAAABJRU5ErkJggg==',
    ),
  );

  CropReview<String>? review;

  setUp(() => review = null);

  Future<void> open(
    WidgetTester tester,
    Future<String> Function() onSend,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                review = await showCropPreviewDialog<String>(
                  context,
                  bytes,
                  onSend: onSend,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the image with its three actions', (tester) async {
    await open(tester, () async => 'ok');

    expect(find.text('Revisá la imagen'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Recortar de nuevo'), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
    expect(find.text(cropSendErrorMessage), findsNothing);
  });

  testWidgets('stays open with progress while the request runs',
      (tester) async {
    final request = Completer<String>();
    await open(tester, () => request.future);

    await tester.tap(find.text('Enviar'));
    await tester.pump();

    expect(find.text('Enviando la imagen…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Revisá la imagen'), findsOneWidget);

    // The other actions are disabled meanwhile.
    await tester.tap(find.text('Cancelar'));
    await tester.tap(find.text('Recortar de nuevo'));
    await tester.pump();
    expect(find.text('Revisá la imagen'), findsOneWidget);
    expect(review, isNull);

    request.complete('scan-result');
    await tester.pumpAndSettle();

    expect(find.text('Revisá la imagen'), findsNothing);
    expect(review?.action, CropPreviewAction.send);
    expect(review?.value, 'scan-result');
  });

  testWidgets('keeps the dialog open with an error when the request fails',
      (tester) async {
    await open(tester, () async => throw Exception('down'));

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Revisá la imagen'), findsOneWidget);
    expect(find.text(cropSendErrorMessage), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Enviando la imagen…'), findsNothing);
    expect(review, isNull);
  });

  testWidgets('retrying sends the same image again until it succeeds',
      (tester) async {
    var attempts = 0;
    await open(tester, () async {
      attempts++;
      if (attempts == 1) throw Exception('down');
      return 'second-try';
    });

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text(cropSendErrorMessage), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Revisá la imagen'), findsNothing);
    expect(review?.action, CropPreviewAction.send);
    expect(review?.value, 'second-try');
  });

  testWidgets('the error clears while the retry is running', (tester) async {
    var attempts = 0;
    final retry = Completer<String>();
    await open(tester, () {
      attempts++;
      if (attempts == 1) return Future<String>.error(Exception('down'));
      return retry.future;
    });

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text(cropSendErrorMessage), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(find.text(cropSendErrorMessage), findsNothing);
    expect(find.text('Enviando la imagen…'), findsOneWidget);

    retry.complete('done');
    await tester.pumpAndSettle();
    expect(review?.value, 'done');
  });

  testWidgets('after a failure the user can still crop again', (tester) async {
    await open(tester, () async => throw Exception('down'));

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recortar de nuevo'));
    await tester.pumpAndSettle();

    expect(review?.action, CropPreviewAction.recrop);
    expect(review?.value, isNull);
  });

  testWidgets('cancelling closes the dialog without sending', (tester) async {
    var sent = false;
    await open(tester, () async {
      sent = true;
      return 'ok';
    });

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(review?.action, CropPreviewAction.cancel);
    expect(sent, isFalse);
  });
}
