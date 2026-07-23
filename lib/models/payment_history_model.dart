class PaymentHistoryModel {
  final int id;
  final String userId;
  final String intentId;
  final String platform;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String price;
  final String note;
  final String way;

  PaymentHistoryModel({
    required this.id,
    required this.userId,
    required this.intentId,
    required this.platform,
    required this.updatedAt,
    required this.createdAt,
    required this.price,
    required this.note,
    required this.way,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      intentId: json['intent_id']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      price: json['price']?.toString() ?? '0',
      note: json['note']?.toString() ?? '',
      way: json['way']?.toString() ?? '',
    );
  }

  // استخراج اسم الخطة من note
  String get planName {
    if (note.contains('Package ID:')) {
      final match = RegExp(r'Package ID:\s*\{([^}]+)\}').firstMatch(note);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Unknown';
      }
    }
    return 'Unknown';
  }

  // تنسيق السعر
  String get formattedPrice {
    return '\$$price';
  }

  // تنسيق التاريخ
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
