import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/ai/scan_failure.dart';
import 'package:luma/core/ai/scan_stage.dart';
import 'package:luma/core/widgets/cropper/crop_preview_dialog.dart';

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

  const second = Duration(seconds: 1);

  Future<void> openStaged(
    WidgetTester tester,
    Future<String> Function(ScanProgress report) onSend,
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

  /// For tests that do not care about the reported stages.
  Future<void> open(
    WidgetTester tester,
    Future<String> Function() onSend,
  ) =>
      openStaged(tester, (_) => onSend());

  /// Lets a successful send finish. After the scan ends the popup still shows
  /// "Todo listo" for a stage, and settling only waits for frames, not for
  /// timers, so the time is advanced by hand first.
  Future<void> finishSend(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  /// Taps "Enviar", lets the failure show in the popup and closes it, which
  /// leaves the preview with its error.
  Future<void> sendAndCloseFailure(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar'));
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

    // The progress is shown in a popup over the preview.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Preparando la imagen'), findsOneWidget);
    // One spinner, in the popup; the buttons only keep their labels.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    expect(find.text('Enviar'), findsOneWidget);
    expect(find.text('Revisá la imagen'), findsOneWidget);

    expect(review, isNull);

    request.complete('scan-result');
    await finishSend(tester);

    expect(find.text('Revisá la imagen'), findsNothing);
    expect(review?.action, CropPreviewAction.send);
    expect(review?.value, 'scan-result');
  });

  testWidgets('disables every button while sending', (tester) async {
    final request = Completer<String>();
    await open(tester, () => request.future);

    await tester.tap(find.text('Enviar'));
    await tester.pump();

    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Recortar de nuevo'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Enviar'))
          .onPressed,
      isNull,
    );

    request.complete('done');
    await finishSend(tester);
  });

  testWidgets('fades every button while sending', (tester) async {
    final request = Completer<String>();
    await open(tester, () => request.future);

    await tester.tap(find.text('Enviar'));
    await tester.pump();

    expect(
      tester
          .widget<Text>(find.text('Cancelar'))
          .style
          ?.color
          ?.a,
      lessThan(1),
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Recortar de nuevo'),
          )
          .style!
          .foregroundColor!
          .resolve({WidgetState.disabled})!
          .a,
      lessThan(1),
    );

    request.complete('done');
    await finishSend(tester);
  });

  testWidgets('keeps the dialog open with an error when the request fails',
      (tester) async {
    await open(tester, () async => throw Exception('down'));

    await sendAndCloseFailure(tester, 'Enviar');

    expect(find.text('Revisá la imagen'), findsOneWidget);
    expect(find.text(cropSendErrorMessage), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Preparando la imagen'), findsNothing);
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

    await sendAndCloseFailure(tester, 'Enviar');
    expect(find.text(cropSendErrorMessage), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await finishSend(tester);

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

    await sendAndCloseFailure(tester, 'Enviar');
    expect(find.text(cropSendErrorMessage), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(cropSendErrorMessage), findsNothing);
    expect(find.text('Preparando la imagen'), findsOneWidget);

    retry.complete('done');
    await finishSend(tester);
    expect(review?.value, 'done');
  });

  testWidgets('after a failure the user can still crop again', (tester) async {
    await open(tester, () async => throw Exception('down'));

    await sendAndCloseFailure(tester, 'Enviar');
    await tester.tap(find.text('Recortar de nuevo'));
    await tester.pumpAndSettle();

    expect(review?.action, CropPreviewAction.recrop);
    expect(review?.value, isNull);
  });

  testWidgets('shows the message of a classified scan failure', (tester) async {
    const failure = ScanFailure(
      function: 'gemini-image-reader',
      kind: ScanFailureKind.quota,
    );
    await open(tester, () async => throw failure);

    await sendAndCloseFailure(tester, 'Enviar');

    expect(find.text(failure.userMessage), findsOneWidget);
    expect(find.text(cropSendErrorMessage), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('a different failure replaces the message on retry',
      (tester) async {
    var attempts = 0;
    const first = ScanFailure(
      function: 'gemini-image-reader',
      kind: ScanFailureKind.parse,
    );
    await open(tester, () async {
      attempts++;
      if (attempts == 1) throw first;
      throw Exception('down');
    });

    await sendAndCloseFailure(tester, 'Enviar');
    expect(find.text(first.userMessage), findsOneWidget);

    await sendAndCloseFailure(tester, 'Reintentar');

    expect(find.text(first.userMessage), findsNothing);
    expect(find.text(cropSendErrorMessage), findsOneWidget);
  });

  testWidgets('the popup follows the stages the scan reports', (tester) async {
    final request = Completer<String>();
    late ScanProgress report;
    await openStaged(tester, (r) {
      report = r;
      return request.future;
    });

    await tester.tap(find.text('Enviar'));
    await tester.pump();
    expect(find.text('Preparando la imagen'), findsOneWidget);

    // Each stage is held for a full second before the next one shows.
    report(ScanStage.sending);
    await tester.pump(second);
    expect(find.text('Enviando y esperando respuesta'), findsOneWidget);

    report(ScanStage.processing);
    await tester.pump(second);
    expect(find.text('Procesando el resultado'), findsOneWidget);

    request.complete('scan-result');
    await tester.pump(second);
    expect(find.text('Todo listo'), findsOneWidget);
    // Still open: "Todo listo" is shown for a second first.
    expect(find.text('Revisá la imagen'), findsOneWidget);
    expect(review, isNull);

    await finishSend(tester);
    expect(find.text('Todo listo'), findsNothing);
    expect(find.text('Revisá la imagen'), findsNothing);
    expect(review?.action, CropPreviewAction.send);
    expect(review?.value, 'scan-result');
  });

  testWidgets('a failure in a stage is shown in the popup', (tester) async {
    const failure = ScanFailure(
      function: 'gemini-image-reader',
      kind: ScanFailureKind.upstream,
    );
    await openStaged(tester, (report) async {
      report(ScanStage.sending);
      throw failure;
    });

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo completar el envío'), findsOneWidget);
    expect(find.text(failure.userMessage), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    // The preview is still there, underneath, and has not finished yet.
    expect(find.text('Revisá la imagen'), findsOneWidget);
    expect(review, isNull);
  });

  testWidgets('closing the popup goes back to the preview with the error',
      (tester) async {
    await open(tester, () async => throw Exception('down'));

    await sendAndCloseFailure(tester, 'Enviar');

    expect(find.text('No se pudo preparar la imagen'), findsNothing);
    expect(find.text('Revisá la imagen'), findsOneWidget);
    expect(find.text(cropSendErrorMessage), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Reintentar'))
          .onPressed,
      isNotNull,
    );
    expect(review, isNull);
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
