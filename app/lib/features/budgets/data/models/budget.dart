class Budget {
  final String id;
  final String categoryId;
  final String categoryName;
  final String categoryType;
  final String? categoryColor;
  final String? categoryIcon;
  final double amount;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.amount,
    this.categoryColor,
    this.categoryIcon,
  });

  /// Espera una fila de `budgets` con el join embebido de Supabase:
  /// `.select('*, categories(name, type, color, icon)')`.
  factory Budget.fromMap(Map<String, dynamic> map) {
    final category = map['categories'] as Map<String, dynamic>?;
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      categoryName: category?['name'] as String? ?? 'Categoría',
      categoryType: category?['type'] as String? ?? 'expense',
      categoryColor: category?['color'] as String?,
      categoryIcon: category?['icon'] as String?,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}
