class Account {
  final String id;
  final String name;
  final String currency;
  final double balance;
  final String? color;
  final String? icon;
  final bool isActive;

  const Account({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    this.color,
    this.icon,
    required this.isActive,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      currency: map['currency'] as String,
      balance: (map['balance'] as num).toDouble(),
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      isActive: map['is_active'] as bool,
    );
  }
}
