class Service {
  final String id;
  final String? categoryId;
  final String name;
  final double approximateAmount;
  final int? dueDay;
  final bool isActive;

  const Service({
    required this.id,
    this.categoryId,
    required this.name,
    required this.approximateAmount,
    this.dueDay,
    required this.isActive,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      name: map['name'] as String,
      approximateAmount: (map['approximate_amount'] as num).toDouble(),
      dueDay: map['due_day'] as int?,
      isActive: map['is_active'] as bool,
    );
  }
}
