// lib/modules/payment/models/plan_model.dart

class PlanModel {
  final String id;
  final String name;        // ← يأتي من API كما هو (English)
  final int price;
  final int agents;
  final int inboxes;
  final List<String> features;  // ← يأتي من API كما هي (English keys)

  PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.agents,
    required this.inboxes,
    required this.features,
  });

  factory PlanModel.fromJson(String id, Map<String, dynamic> json) {
    return PlanModel(
      id: id,
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      agents: json['limits']?['agents'] ?? 0,
      inboxes: json['limits']?['inboxes'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
    );
  }

  // ✅ New method for the new API format
  factory PlanModel.fromJsonNew(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toInt() : 0,
      agents: json['limits']?['agents'] ?? 0,
      inboxes: json['limits']?['inboxes'] ?? 0,
      features: (json['features'] as List<dynamic>?)
              ?.map((f) => f['name']?.toString() ?? '')
              .toList() ??
          [],
    );
  }

  // ✅ السعر فقط — لا توجد ترجمة هنا!
  double get priceInDollars => price / 100;
  String get formattedPrice => '\$${priceInDollars.toStringAsFixed(2)}';

// ❌ حذفنا getFeatureLabel و localizedFeatures
}