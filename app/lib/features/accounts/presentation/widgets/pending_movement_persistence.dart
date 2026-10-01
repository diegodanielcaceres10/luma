import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import 'pending_movements_section.dart';

/// Differences smaller than this are treated as zero (double rounding noise).
const kRemainderEpsilon = 0.005;

/// Persists one [PendingMovement] as a real transaction on [accountId].
///
/// Throws an [Exception] carrying the view model's message on failure.
Future<void> savePendingMovement({
  required PendingMovement movement,
  required String userId,
  required String accountId,
  required TransactionViewModel transactionViewModel,
  required InvoiceViewModel invoiceViewModel,
}) async {
  final bool success = switch (movement) {
    CategoryPendingMovement(:final category, :final type) =>
      await transactionViewModel.createTransaction(
        userId: userId,
        accountId: accountId,
        categoryId: category?.id,
        type: type,
        amount: movement.amount.abs(),
        description: movement.description,
        date: movement.date,
      ),
    // Only this account's side is persisted; the other account's side is
    // registered manually by the user.
    TransferPendingMovement() => await transactionViewModel.createTransfer(
        userId: userId,
        accountId: accountId,
        type: movement.amount < 0 ? 'expense' : 'income',
        amount: movement.amount.abs(),
        date: movement.date,
        description: movement.description ?? movement.displayLabel,
      ),
    InvoicePendingMovement(:final invoice, :final category) =>
      await invoiceViewModel.payInvoice(
        invoice: invoice,
        userId: userId,
        accountId: accountId,
        categoryId: category.id,
        amount: movement.amount.abs(),
        description: movement.description,
        date: movement.date,
      ),
  };
  if (success) return;

  final errorMessage = movement is InvoicePendingMovement
      ? invoiceViewModel.errorMessage
      : transactionViewModel.errorMessage;
  throw Exception(errorMessage ?? 'No se pudo guardar un movimiento.');
}
