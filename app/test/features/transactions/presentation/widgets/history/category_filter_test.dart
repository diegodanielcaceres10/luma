import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/widgets/history/category_filter.dart';

void main() {
  const food = TransactionCategory(id: 'c1', name: 'Comida');
  const rent = TransactionCategory(id: 'c2', name: 'Alquiler');
  const uncategorized = TransactionCategory(name: 'Sin categoría');

  Future<void> pump(
    WidgetTester tester, {
    required List<TransactionCategory> categories,
    String? selectedKey,
    ValueChanged<String?>? onChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: TransactionsCategoryFilter(
              categories: categories,
              selectedKey: selectedKey,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  double topOf(WidgetTester tester, String label) =>
      tester.getTopLeft(find.text(label)).dy;

  testWidgets('puts Todas and Sin categoría on the first line', (tester) async {
    await pump(tester, categories: [food, rent, uncategorized]);

    expect(topOf(tester, 'Todas'), topOf(tester, 'Sin categoría'));
  });

  testWidgets('lists the real categories on a line below', (tester) async {
    await pump(tester, categories: [food, rent, uncategorized]);

    expect(topOf(tester, 'Comida'), greaterThan(topOf(tester, 'Todas')));
    expect(topOf(tester, 'Comida'), topOf(tester, 'Alquiler'));
  });

  testWidgets('keeps Sin categoría out of the category list', (tester) async {
    await pump(tester, categories: [food, uncategorized]);

    expect(find.text('Sin categoría'), findsOneWidget);
    expect(topOf(tester, 'Sin categoría'), topOf(tester, 'Todas'));
  });

  testWidgets('a real category named like the placeholder stays in the list',
      (tester) async {
    const lookalike = TransactionCategory(id: 'c3', name: 'Sin categoría');
    await pump(tester, categories: [lookalike]);

    expect(topOf(tester, 'Sin categoría'), greaterThan(topOf(tester, 'Todas')));
  });

  testWidgets('hides Sin categoría when nothing is uncategorized',
      (tester) async {
    await pump(tester, categories: [food, rent]);

    expect(find.text('Sin categoría'), findsNothing);
    expect(find.text('Todas'), findsOneWidget);
  });

  testWidgets('has no second line without real categories', (tester) async {
    await pump(tester, categories: [uncategorized]);

    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Sin categoría'), findsOneWidget);
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('reports the key of the tapped chip', (tester) async {
    final taps = <String?>[];
    await pump(
      tester,
      categories: [food, uncategorized],
      selectedKey: 'c1',
      onChanged: taps.add,
    );

    await tester.tap(find.text('Todas'));
    await tester.tap(find.text('Sin categoría'));
    await tester.tap(find.text('Comida'));

    expect(taps, [null, 'Sin categoría', 'c1']);
  });
}
