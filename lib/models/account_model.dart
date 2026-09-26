class AccountModel {
  final String id;
  final String userId;
  final String accountName;
  final String accountType; // 'bank', 'cash', 'wallet', 'other'
  final double openingBalance;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountModel({
    required this.id,
    required this.userId,
    required this.accountName,
    required this.accountType,
    required this.openingBalance,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      accountName: map['account_name']?.toString() ?? map['name']?.toString() ?? 'Account',
      accountType: map['account_type']?.toString() ?? map['type']?.toString() ?? 'bank',
      openingBalance: (map['opening_balance'] is num)
          ? (map['opening_balance'] as num).toDouble()
          : double.parse(map['opening_balance']?.toString() ?? '0.0'),
      color: map['color']?.toString(),
      icon: map['icon']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'account_name': accountName,
      'account_type': accountType,
      'opening_balance': openingBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id.length == 36 && !id.startsWith('acc-') && !id.startsWith('def-')) {
      map['id'] = id;
    }
    if (color != null && color!.isNotEmpty) {
      map['color'] = color;
    }
    if (icon != null && icon!.isNotEmpty) {
      map['icon'] = icon;
    }
    return map;
  }

  AccountModel copyWith({
    String? id,
    String? userId,
    String? accountName,
    String? accountType,
    double? openingBalance,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      openingBalance: openingBalance ?? this.openingBalance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
