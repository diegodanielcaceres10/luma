class Invoice {
  final String id;
  final String serviceId;
  final int month;
  final int year;
  final double amount;
  final DateTime? dueDate;
  final bool paid;
  final DateTime? paidAt;
  final String? transactionId;

  const Invoice({
    required this.id,
    required this.serviceId,
    required this.month,
    required this.year,
    required this.amount,
    this.dueDate,
    required this.paid,
    this.paidAt,
    this.transactionId,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      serviceId: map['service_id'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      amount: (map['amount'] as num).toDouble(),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      paid: map['paid'] as bool,
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : null,
      transactionId: map['transaction_id'] as String?,
    );
  }
}
