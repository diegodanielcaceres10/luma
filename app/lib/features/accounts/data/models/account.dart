class Account {
  final String id;
  final String name;
  final double balance;
  final String? color;
  final bool isActive;

  const Account({
    required this.id,
    required this.name,
    required this.balance,
    this.color,
    required this.isActive,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      color: map['color'] as String?,
      isActive: map['is_active'] as bool,
    );
  }
}
