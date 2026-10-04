import '../../../../categories/data/models/category.dart';
import '../../../../invoices/data/models/invoice.dart';

/// A movement (income, expense, transfer or paid invoice) accumulated by
/// [PendingMovementsSection] before it is actually persisted. The owning
/// screen decides how (and whether) each one is turned into a real
/// transaction once the user confirms.
sealed class PendingMovement {
  final double amount;
  final String? description;
  final DateTime date;

  const PendingMovement({
    required this.amount,
    required this.date,
    this.description,
  });

  String get displayLabel;
}

class CategoryPendingMovement extends PendingMovement {
  /// Null when the movement was registered without a category.
  final Category? category;

  /// 'income' or 'expense'. Kept apart from [category] because it must
  /// survive a missing category.
  final String type;

  const CategoryPendingMovement({
    required super.amount,
    required super.date,
    required this.type,
    this.category,
    super.description,
  });

  @override
  String get displayLabel => category?.name ?? 'Sin categoría';
}

class TransferPendingMovement extends PendingMovement {
  final String otherAccountId;
  final String otherAccountName;

  const TransferPendingMovement({
    required super.amount,
    required super.date,
    required this.otherAccountId,
    required this.otherAccountName,
    super.description,
  });

  @override
  String get displayLabel => amount >= 0
      ? 'Transferencia desde $otherAccountName'
      : 'Transferencia a $otherAccountName';
}

class InvoicePendingMovement extends PendingMovement {
  final Invoice invoice;
  final Category category;
  final String serviceName;

  const InvoicePendingMovement({
    required super.amount,
    required super.date,
    required this.invoice,
    required this.category,
    required this.serviceName,
    super.description,
  });

  @override
  String get displayLabel => 'Factura · $serviceName';
}

enum PendingMovementKind { income, expense, transfer, invoice }

const kMonthAbbreviations = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];
