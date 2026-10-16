import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/invoices/data/models/invoice.dart';
import 'package:luma/features/invoices/presentation/view_models/invoice_view_model.dart';
import 'package:luma/features/services/data/models/service.dart';
import 'package:luma/features/transactions/presentation/view_models/transaction_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/fakes.dart';

Invoice invoice({
  String id = 'inv-1',
  String serviceId = 'svc-1',
  int? month,
  int? year,
  double amount = 100,
  bool paid = false,
  bool cancelled = false,
}) {
  final now = DateTime.now();
  return Invoice(
    id: id,
    serviceId: serviceId,
    month: month ?? now.month,
    year: year ?? now.year,
    amount: amount,
    paid: paid,
    cancelled: cancelled,
  );
}

Service service(String id, double approximateAmount) => Service(
      id: id,
      name: id,
      approximateAmount: approximateAmount,
      isActive: true,
    );

void main() {
  late FakeInvoiceRepository repository;
  late FakeTransactionRepository transactionRepository;
  late InvoiceViewModel viewModel;

  setUp(() {
    repository = FakeInvoiceRepository();
    transactionRepository = FakeTransactionRepository();
    viewModel = InvoiceViewModel(
      repository,
      TransactionViewModel(
        transactionRepository,
        FakeMonthlyBalanceRepository(),
      ),
    );
  });

  tearDown(() => viewModel.dispose());

  Future<bool> create() => viewModel.createInvoice(
        userId: 'user-1',
        serviceId: 'svc-1',
        month: 10,
        year: 2026,
        amount: 80,
      );

  Future<bool> pay({({int month, int year})? justifying}) =>
      viewModel.payInvoice(
        invoice: invoice(id: 'inv-9'),
        userId: 'user-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        amount: 95,
        justifying: justifying,
      );

  group('loadInvoices', () {
    test('fills the list and marks the view model as loaded', () async {
      repository.invoices = [invoice(id: 'a'), invoice(id: 'b')];

      await viewModel.loadInvoices();

      expect(viewModel.invoices.map((i) => i.id), ['a', 'b']);
      expect(viewModel.hasLoaded, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('notifies when loading starts and when it ends', () async {
      final states = <bool>[];
      viewModel.addListener(() => states.add(viewModel.isLoading));

      await viewModel.loadInvoices();

      expect(states, [true, false]);
    });

    test('reports an error without throwing when the repository fails',
        () async {
      repository.loadError = Exception('network down');

      await viewModel.loadInvoices();

      expect(viewModel.errorMessage, 'No se pudieron cargar las facturas.');
      expect(viewModel.invoices, isEmpty);
      expect(viewModel.hasLoaded, isFalse);
      expect(viewModel.isLoading, isFalse);
    });

    test('clears a previous error on a successful reload', () async {
      repository.loadError = Exception('network down');
      await viewModel.loadInvoices();

      repository.loadError = null;
      await viewModel.loadInvoices();

      expect(viewModel.errorMessage, isNull);
      expect(viewModel.hasLoaded, isTrue);
    });
  });

  group('createInvoice', () {
    test('returns true and reloads the list', () async {
      repository.invoices = [invoice(id: 'new')];

      final created = await create();

      expect(created, isTrue);
      expect(repository.createCalls, 1);
      expect(repository.getAllCalls, 1);
      expect(viewModel.invoices.map((i) => i.id), ['new']);
      expect(viewModel.submitError, isNull);
      expect(viewModel.isSubmitting, isFalse);
    });

    test('flags a duplicate when the database reports a unique violation',
        () async {
      repository.writeError = const PostgrestException(
        message: 'duplicate key',
        code: '23505',
      );

      final created = await create();

      expect(created, isFalse);
      expect(viewModel.submitError, InvoiceSubmitError.duplicate);
      expect(
        viewModel.errorMessage,
        'Ya existe una factura de ese servicio para ese mes.',
      );
      expect(viewModel.isSubmitting, isFalse);
    });

    test('flags a generic error for any other database error', () async {
      repository.writeError = const PostgrestException(
        message: 'boom',
        code: '42000',
      );

      final created = await create();

      expect(created, isFalse);
      expect(viewModel.submitError, InvoiceSubmitError.generic);
      expect(viewModel.errorMessage, 'No se pudo guardar la factura.');
    });

    test('flags a generic error for a non-database exception', () async {
      repository.writeError = Exception('boom');

      final created = await create();

      expect(created, isFalse);
      expect(viewModel.submitError, InvoiceSubmitError.generic);
      expect(viewModel.isSubmitting, isFalse);
    });
  });

  group('cancelInvoice', () {
    test('cancels through the repository and reloads', () async {
      final cancelled = await viewModel.cancelInvoice('inv-1');

      expect(cancelled, isTrue);
      expect(repository.cancelledIds, ['inv-1']);
      expect(repository.getAllCalls, 1);
    });

    test('marks the invoice as cancelling only while it runs', () async {
      final seen = <bool>[];
      viewModel.addListener(() => seen.add(viewModel.isCancelling('inv-1')));

      await viewModel.cancelInvoice('inv-1');

      expect(seen.first, isTrue);
      expect(viewModel.isCancelling('inv-1'), isFalse);
    });

    test('reports an error and returns false when the repository fails',
        () async {
      repository.writeError = Exception('boom');

      final cancelled = await viewModel.cancelInvoice('inv-1');

      expect(cancelled, isFalse);
      expect(viewModel.errorMessage, 'No se pudo cancelar la factura.');
      expect(viewModel.isCancelling('inv-1'), isFalse);
    });
  });

  group('payInvoice', () {
    test('creates the expense and marks the invoice as paid with its id',
        () async {
      transactionRepository.createdId = 'tx-42';

      final paid = await pay();

      expect(paid, isTrue);
      expect(transactionRepository.createCalls, 1);
      expect(repository.paid, [(id: 'inv-9', transactionId: 'tx-42')]);
      expect(viewModel.isPaying('inv-9'), isFalse);
    });

    test('registers a justifying transaction when justifying is given',
        () async {
      final paid = await pay(justifying: (month: 9, year: 2026));

      expect(paid, isTrue);
      expect(transactionRepository.createCalls, 0);
      expect(transactionRepository.justifying, [(month: 9, year: 2026)]);
      expect(repository.paid, hasLength(1));
    });

    test('does not mark the invoice as paid when the expense fails',
        () async {
      transactionRepository.createError = Exception('boom');

      final paid = await pay();

      expect(paid, isFalse);
      expect(repository.paid, isEmpty);
      expect(viewModel.errorMessage, 'No se pudo guardar la transacción.');
      expect(viewModel.isPaying('inv-9'), isFalse);
    });

    test('reports an error when marking the invoice as paid fails',
        () async {
      repository.writeError = Exception('boom');

      final paid = await pay();

      expect(paid, isFalse);
      expect(viewModel.errorMessage, 'No se pudo registrar el pago.');
      expect(viewModel.isPaying('inv-9'), isFalse);
    });
  });

  group('current month figures', () {
    test('pendingCountForCurrentMonth counts only pending invoices of the '
        'current month', () async {
      final now = DateTime.now();
      final otherMonth = DateTime(now.year, now.month - 1);
      repository.invoices = [
        invoice(id: 'pending-1'),
        invoice(id: 'pending-2'),
        invoice(id: 'paid', paid: true),
        invoice(id: 'cancelled', cancelled: true),
        invoice(
          id: 'old',
          month: otherMonth.month,
          year: otherMonth.year,
        ),
      ];
      await viewModel.loadInvoices();

      expect(viewModel.pendingCountForCurrentMonth, 2);
    });

    test('pendingAmountForCurrentMonth uses the invoice, the approximate '
        'amount, or nothing once resolved', () async {
      repository.invoices = [
        invoice(id: 'i1', serviceId: 'pending', amount: 120),
        invoice(id: 'i2', serviceId: 'paid', paid: true, amount: 999),
        invoice(id: 'i3', serviceId: 'cancelled', cancelled: true, amount: 999),
      ];
      await viewModel.loadInvoices();

      final total = viewModel.pendingAmountForCurrentMonth([
        service('pending', 10),
        service('paid', 50),
        service('cancelled', 60),
        service('no-invoice', 30),
      ]);

      expect(total, 150);
    });
  });
}
