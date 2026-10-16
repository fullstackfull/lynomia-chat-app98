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

  /// The plan's name, dug out of the server's free-text note, or EMPTY when the note does not carry
  /// one. It used to return the literal English word 'Unknown', which was then drawn as the row's
  /// title in both languages; what to show instead is the view's decision and the view can translate.
  String get planName {
    final match = RegExp(r'Package ID:\s*\{([^}]+)\}').firstMatch(note);
    return match?.group(1)?.trim() ?? '';
  }

  String get formattedPrice => '\$$price';

  // `formattedDate` was here: '${createdAt.day}/${createdAt.month}/${createdAt.year}', which is
  // unpadded, ambiguous between day-first and month-first, and in Latin digits and slashes in the
  // middle of an Arabic screen. A date is formatted at the view now, where the locale is known.
}
