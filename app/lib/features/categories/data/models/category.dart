class Category {
  final String id;
  final String name;
  final String type; // income | expense
  final String? color;
  final String? icon;
  final bool hasBudget;
  final double? budgetAmount;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.color,
    this.icon,
    this.hasBudget = false,
    this.budgetAmount,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      hasBudget: map['has_budget'] as bool? ?? false,
      budgetAmount: (map['budget_amount'] as num?)?.toDouble(),
    );
  }
}
