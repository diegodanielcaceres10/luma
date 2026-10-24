import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/categories/data/models/category.dart';
import 'package:luma/features/comparison/presentation/view_models/month_comparison.dart';
import 'package:luma/features/invoices/data/models/invoice.dart';
import 'package:luma/features/services/data/models/service.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';

TransactionEntry entry(
  String type,
  double amount, {
  String? categoryId,
  String category = 'Sin categoría',
  bool isTransfer = false,
}) {
  return TransactionEntry(
    id: '$type-$amount-$categoryId',
    type: type,
    amount: amount,
    date: DateTime(2026, 9, 10),
    category: TransactionCategory(
      id: categoryId,
      name: category,
      color: '#112233',
    ),
    account: const TransactionAccount(name: 'Cuenta'),
    isTransfer: isTransfer,
  );
}

MonthSnapshot snap(
  int month,
  List<TransactionEntry> entries, {
  double uncontrolled = 0,
}) {
  return MonthSnapshot(
    month: DateTime(2026, month),
    entries: entries,
    uncontrolledTotal: uncontrolled,
  );
}

Invoice invoice(
  String serviceId,
  int month,
  double amount, {
  bool cancelled = false,
}) {
  return Invoice(
    id: '$serviceId-$month-$amount',
    serviceId: serviceId,
    month: month,
    year: 2026,
    amount: amount,
    paid: false,
    cancelled: cancelled,
  );
}

MonthComparison compare(
  MonthSnapshot before,
  MonthSnapshot after, {
  List<Category> categories = const [],
  List<Service> services = const [],
  List<Invoice> invoices = const [],
}) {
  return MonthComparison.compute(
    before: before,
    after: after,
    categories: categories,
    services: services,
    invoices: invoices,
  );
}

ComparisonRow byId(List<ComparisonRow> rows, String id) {
  return rows.firstWhere((r) => r.id == id);
}

void main() {
  group('MonthComparison summary', () {
    final baseBefore = snap(9, [
      entry('income', 1000),
      entry('expense', 400),
    ]);
    final baseAfter = snap(
      10,
      [entry('income', 1200), entry('expense', 500)],
      uncontrolled: -50,
    );

    test('mirrors Estadísticas and adds Sin declarar', () {
      final result = compare(baseBefore, baseAfter);

      expect(
        result.summary.map((r) => r.id),
        ['income', 'expenses', 'balance', 'undeclared'],
      );
      expect(
        result.summary.map((r) => r.label),
        ['Ingresos', 'Gastos', 'Balance', 'Sin declarar'],
      );

      final income = byId(result.summary, 'income');
      expect(income.before, 1000);
      expect(income.after, 1200);
      expect(income.difference, 200);
      expect(income.percentChange, closeTo(20, 0.01));
      expect(income.tone, ComparisonTone.favorable);

      final expenses = byId(result.summary, 'expenses');
      expect(expenses.before, 400);
      expect(expenses.after, 550);
      expect(expenses.tone, ComparisonTone.unfavorable);

      final balance = byId(result.summary, 'balance');
      expect(balance.before, 600);
      expect(balance.after, 650);
      expect(balance.tone, ComparisonTone.favorable);

      final undeclared = byId(result.summary, 'undeclared');
      expect(undeclared.before, 0);
      expect(undeclared.after, 50);
      expect(undeclared.isNew, isTrue);
      expect(undeclared.tone, ComparisonTone.unfavorable);
    });

    test('ignores transfers', () {
      final before = snap(9, [
        entry('income', 1000),
        entry('expense', 400),
        entry('expense', 999, isTransfer: true),
      ]);

      final result = compare(before, baseAfter);

      expect(byId(result.summary, 'expenses').before, 400);
    });

    test('hides Sin declarar when both months are zero', () {
      final after = snap(10, [entry('income', 1200), entry('expense', 500)]);

      final result = compare(baseBefore, after);

      expect(result.summary.map((r) => r.id), ['income', 'expenses', 'balance']);
    });

    test('a positive uncontrolled adjustment shows as a negative amount', () {
      final after = snap(10, [entry('income', 1200)], uncontrolled: 30);

      final result = compare(baseBefore, after);

      final undeclared = byId(result.summary, 'undeclared');
      expect(undeclared.after, -30);
      expect(undeclared.difference, -30);
      expect(undeclared.tone, ComparisonTone.favorable);
    });
  });

  group('MonthComparison categories', () {
    test('are joined by id and ordered by the largest change', () {
      final before = snap(9, [
        entry('expense', 82, categoryId: 'c1', category: 'Comida'),
        entry('expense', 40, categoryId: 'c2', category: 'Transporte'),
      ]);
      final after = snap(10, [
        entry('expense', 95, categoryId: 'c1', category: 'Comida'),
        entry('expense', 31, categoryId: 'c2', category: 'Transporte'),
        entry('expense', 60, categoryId: 'c3', category: 'Hogar'),
      ]);

      final rows = compare(before, after).categories;

      expect(rows.map((r) => r.id), ['c3', 'c1', 'c2']);

      final c3 = byId(rows, 'c3');
      expect(c3.isNew, isTrue);
      expect(c3.before, 0);
      expect(c3.percentChange, isNull);

      final c1 = byId(rows, 'c1');
      expect(c1.difference, 13);
      expect(c1.percentChange, closeTo(15.85, 0.01));
      expect(c1.tone, ComparisonTone.unfavorable);
      expect(c1.colorHex, '#112233');

      final c2 = byId(rows, 'c2');
      expect(c2.difference, -9);
      expect(c2.percentChange, closeTo(-22.5, 0.01));
      expect(c2.tone, ComparisonTone.favorable);
    });

    test('a category that disappears shows -100%', () {
      final before = snap(9, [
        entry('expense', 40, categoryId: 'c2', category: 'Transporte'),
      ]);
      final after = snap(10, []);

      final row = byId(compare(before, after).categories, 'c2');

      expect(row.after, 0);
      expect(row.percentChange, closeTo(-100, 0.01));
    });

    test('uncategorized entries are grouped in one row', () {
      final before = snap(9, [
        entry('expense', 10),
        entry('expense', 5),
      ]);
      final after = snap(10, []);

      final rows = compare(before, after).categories;

      expect(rows, hasLength(1));
      expect(rows.single.id, 'uncategorized');
      expect(rows.single.label, 'Sin categoría');
      expect(rows.single.before, 15);
    });

    test('budget shows only when the category has one', () {
      final before = snap(9, [
        entry('expense', 80, categoryId: 'c1', category: 'Comida'),
        entry('expense', 60, categoryId: 'c2', category: 'Transporte'),
      ]);
      final after = snap(10, [
        entry('expense', 85, categoryId: 'c1', category: 'Comida'),
        entry('expense', 65, categoryId: 'c2', category: 'Transporte'),
      ]);

      final rows = compare(
        before,
        after,
        categories: const [
          Category(
            id: 'c1',
            name: 'Comida',
            type: 'expense',
            hasBudget: true,
            budgetAmount: 90,
          ),
          Category(
            id: 'c2',
            name: 'Transporte',
            type: 'expense',
            hasBudget: false,
            budgetAmount: 70,
          ),
        ],
      ).categories;

      expect(byId(rows, 'c1').budget, 90);
      expect(byId(rows, 'c2').budget, isNull);
    });

    test('equal amounts are neutral', () {
      final entries = [
        entry('expense', 50, categoryId: 'c1', category: 'Comida'),
      ];

      final row = byId(
        compare(snap(9, entries), snap(10, entries)).categories,
        'c1',
      );

      expect(row.difference, 0);
      expect(row.tone, ComparisonTone.neutral);
    });
  });

  group('MonthComparison services', () {
    const services = [
      Service(
        id: 's1',
        name: 'Luz',
        approximateAmount: 100,
        isActive: true,
      ),
      Service(
        id: 's2',
        name: 'Agua',
        approximateAmount: 50,
        isActive: true,
      ),
    ];

    test('use the month non-cancelled invoices', () {
      final result = compare(
        snap(9, []),
        snap(10, []),
        services: services,
        invoices: [
          invoice('s1', 9, 100),
          invoice('s2', 9, 50),
          invoice('s1', 10, 120),
          invoice('s3', 10, 30),
          invoice('s1', 10, 999, cancelled: true),
        ],
      );

      final rows = result.services;
      expect(rows.map((r) => r.id), ['s1', 's2', 's3']);

      final s1 = byId(rows, 's1');
      expect(s1.before, 100);
      expect(s1.after, 120);
      expect(s1.difference, 20);
      expect(s1.tone, ComparisonTone.unfavorable);

      final s2 = byId(rows, 's2');
      expect(s2.after, isNull);
      expect(s2.difference, isNull);
      expect(s2.tone, ComparisonTone.neutral);

      final s3 = byId(rows, 's3');
      expect(s3.label, 'Servicio desconocido');
      expect(s3.before, isNull);
      expect(s3.isNew, isFalse);
    });

    test('never change the summary', () {
      final result = compare(
        snap(9, []),
        snap(10, []),
        services: services,
        invoices: [invoice('s1', 9, 100), invoice('s1', 10, 120)],
      );

      final expenses = byId(result.summary, 'expenses');
      expect(expenses.before, 0);
      expect(expenses.after, 0);
    });

    test('a service with zero in both months is hidden', () {
      final result = compare(
        snap(9, []),
        snap(10, []),
        services: services,
        invoices: [invoice('s1', 9, 0), invoice('s1', 10, 0)],
      );

      expect(result.services, isEmpty);
    });
  });

  group('MonthComparison.isEmpty', () {
    test('is true for months without data', () {
      expect(compare(snap(9, []), snap(10, [])).isEmpty, isTrue);
    });

    test('is true when the months only have transfers', () {
      final result = compare(
        snap(9, [entry('expense', 80, isTransfer: true)]),
        snap(10, []),
      );

      expect(result.isEmpty, isTrue);
    });

    test('is false when any month has movements', () {
      final result = compare(snap(9, []), snap(10, [entry('income', 10)]));

      expect(result.isEmpty, isFalse);
    });
  });
}
