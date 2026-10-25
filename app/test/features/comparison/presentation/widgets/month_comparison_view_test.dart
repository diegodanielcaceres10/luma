import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luma/core/utils/app_clock.dart';
import 'package:luma/features/categories/data/models/category.dart';
import 'package:luma/features/comparison/presentation/view_models/month_comparison.dart';
import 'package:luma/features/comparison/presentation/widgets/month_comparison_view.dart';
import 'package:luma/features/invoices/data/models/invoice.dart';
import 'package:luma/features/services/data/models/service.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';

TransactionEntry entry(
  String type,
  double amount, {
  String? categoryId,
  String category = 'Sin categoría',
}) {
  return TransactionEntry(
    id: '$type-$amount-$categoryId',
    type: type,
    amount: amount,
    date: DateTime(2020, 9, 10),
    category: TransactionCategory(id: categoryId, name: category),
    account: const TransactionAccount(name: 'Cuenta'),
  );
}

MonthComparison buildComparison({bool empty = false}) {
  return MonthComparison.compute(
    before: MonthSnapshot(
      month: DateTime(2020, 5),
      entries: empty
          ? const []
          : [
              entry('income', 1000),
              entry('expense', 400, categoryId: 'c1', category: 'Comida'),
            ],
      uncontrolledTotal: 0,
    ),
    after: MonthSnapshot(
      month: DateTime(2020, 6),
      entries: empty
          ? const []
          : [
              entry('income', 1200),
              entry('expense', 500, categoryId: 'c1', category: 'Comida'),
            ],
      uncontrolledTotal: 0,
    ),
    categories: const [
      Category(id: 'c1', name: 'Comida', type: 'expense'),
    ],
    services: const [
      Service(id: 's1', name: 'Luz', approximateAmount: 100, isActive: true),
    ],
    invoices: empty
        ? const []
        : [
            const Invoice(
              id: 'i1',
              serviceId: 's1',
              month: 5,
              year: 2020,
              amount: 80,
              paid: true,
            ),
            const Invoice(
              id: 'i2',
              serviceId: 's1',
              month: 6,
              year: 2020,
              amount: 90,
              paid: false,
            ),
          ],
  );
}

Widget host({
  required ComparisonViewStatus status,
  MonthComparison? comparison,
  DateTime? before,
  DateTime? after,
  VoidCallback? onRetry,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MonthComparisonView(
        beforeMonth: before ?? DateTime(2020, 5),
        afterMonth: after ?? DateTime(2020, 6),
        status: status,
        comparison: comparison,
        currency: 'EUR',
        onBeforeChanged: (_) {},
        onAfterChanged: (_) {},
        onSwap: () {},
        onRetry: onRetry ?? () {},
        onBack: () {},
      ),
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('MonthComparisonView', () {
    testWidgets('loading shows a spinner and no cards', (tester) async {
      await tester.pumpWidget(host(status: ComparisonViewStatus.loading));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Resumen'), findsNothing);
    });

    testWidgets('error shows the message and retries on tap', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        host(status: ComparisonViewStatus.error, onRetry: () => retries++),
      );

      expect(find.text('No se pudo cargar la comparación.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));

      expect(retries, 1);
    });

    testWidgets('sameMonth asks for two different months', (tester) async {
      await tester.pumpWidget(host(
        status: ComparisonViewStatus.sameMonth,
        before: DateTime(2020, 9),
        after: DateTime(2020, 9),
      ));

      expect(find.text('Elegí dos meses distintos'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('ready with data shows the three cards', (tester) async {
      await tester.pumpWidget(host(
        status: ComparisonViewStatus.ready,
        comparison: buildComparison(),
      ));

      expect(find.text('Resumen'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Servicios'), findsOneWidget);
      expect(find.text('Luz'), findsOneWidget);
    });

    testWidgets('ready without categories or services hides those cards',
        (tester) async {
      final summaryOnly = MonthComparison.compute(
        before: MonthSnapshot(
          month: DateTime(2020, 5),
          entries: [entry('income', 1000)],
          uncontrolledTotal: 0,
        ),
        after: MonthSnapshot(
          month: DateTime(2020, 6),
          entries: [entry('income', 1100)],
          uncontrolledTotal: 0,
        ),
        categories: const [],
        services: const [],
        invoices: const [],
      );

      await tester.pumpWidget(host(
        status: ComparisonViewStatus.ready,
        comparison: summaryOnly,
      ));

      expect(find.text('Resumen'), findsOneWidget);
      expect(find.text('Categorías'), findsNothing);
      expect(find.text('Servicios'), findsNothing);
    });

    testWidgets('ready with an empty comparison says there is no data',
        (tester) async {
      await tester.pumpWidget(host(
        status: ComparisonViewStatus.ready,
        comparison: buildComparison(empty: true),
      ));

      expect(find.text('No hay datos en esos meses.'), findsOneWidget);
      expect(find.text('Resumen'), findsNothing);
    });

    testWidgets('warns that the current month is partial', (tester) async {
      final now = nowLocal();
      await tester.pumpWidget(host(
        status: ComparisonViewStatus.ready,
        comparison: buildComparison(),
        before: DateTime(now.year, now.month - 1),
        after: DateTime(now.year, now.month),
      ));

      expect(
        find.text(
          'El mes en curso todavía no terminó: sus valores son parciales.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not warn when both months are past', (tester) async {
      await tester.pumpWidget(host(
        status: ComparisonViewStatus.ready,
        comparison: buildComparison(),
      ));

      expect(find.textContaining('todavía no terminó'), findsNothing);
    });

    testWidgets('does not overflow at 320 px with every block', (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(host(
        status: ComparisonViewStatus.ready,
        comparison: buildComparison(),
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('resolveComparisonStatus', () {
    ComparisonViewStatus resolve({
      bool sameMonth = false,
      bool isLoading = false,
      String? errorMessage,
      bool hasData = false,
      bool dependenciesReady = true,
      bool dependenciesLoading = false,
    }) {
      return resolveComparisonStatus(
        sameMonth: sameMonth,
        isLoading: isLoading,
        errorMessage: errorMessage,
        hasData: hasData,
        dependenciesReady: dependenciesReady,
        dependenciesLoading: dependenciesLoading,
      );
    }

    test('the same month wins over everything', () {
      expect(
        resolve(sameMonth: true, isLoading: true, errorMessage: 'x'),
        ComparisonViewStatus.sameMonth,
      );
    });

    test('loading comes before any error', () {
      expect(
        resolve(isLoading: true, errorMessage: 'x'),
        ComparisonViewStatus.loading,
      );
    });

    test('dependencies still loading keep the spinner', () {
      expect(
        resolve(dependenciesReady: false, dependenciesLoading: true),
        ComparisonViewStatus.loading,
      );
    });

    test('dependencies that are not loaded nor loading are an error', () {
      expect(
        resolve(dependenciesReady: false, dependenciesLoading: false),
        ComparisonViewStatus.error,
      );
    });

    test('a load error is shown as an error', () {
      expect(resolve(errorMessage: 'x'), ComparisonViewStatus.error);
    });

    test('data with everything loaded is ready', () {
      expect(resolve(hasData: true), ComparisonViewStatus.ready);
    });

    test('nothing yet keeps the spinner', () {
      expect(resolve(), ComparisonViewStatus.loading);
    });
  });
}
