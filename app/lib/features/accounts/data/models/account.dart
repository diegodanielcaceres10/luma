class Account {
  final String id;
  final String name;
  final double balance;
  final bool isActive;

  /// Last time [balance] changed (maintained by a database trigger).
  final DateTime balanceUpdatedAt;

  const Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.isActive,
    required this.balanceUpdatedAt,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      isActive: map['is_active'] as bool,
      balanceUpdatedAt:
          DateTime.parse(map['balance_updated_at'] as String).toLocal(),
    );
  }

  // Equality by id: without it, every reload of the accounts list brings new
  // instances and any previous selection (e.g. in a DropdownButtonFormField)
  // stops matching by identity even though it is "the same" account — that
  // is what broke the dropdown in TransactionFormScreen after refreshing the
  // balance.
  @override
  bool operator ==(Object other) => other is Account && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
