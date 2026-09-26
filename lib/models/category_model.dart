class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String icon; // Predefined icon identifier string
  final String? color; // Optional Hex color code, e.g. '0xFFF59E0B'
  final String type; // 'expense' or 'income'
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    this.color,
    required this.type,
    required this.createdAt,
  });

  bool get isIncome => type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'expense';

  factory CategoryModel.fromMap(Map<String, dynamic> map, String type) {
    return CategoryModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      icon: map['icon']?.toString() ?? 'other',
      color: map['color']?.toString(),
      type: type,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.length == 36 && !id.startsWith('cat-') && !id.startsWith('def-')) {
      map['id'] = id;
    }
    if (color != null && color!.isNotEmpty) {
      map['color'] = color;
    }
    return map;
  }

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    String? type,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
