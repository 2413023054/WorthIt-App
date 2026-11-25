import 'dart:convert';

class PurchaseAnalysis {
  final String id;
  final String? userId;
  final String itemName;
  final double price;
  final double budget;
  final String needLevel; // Primer, Sekunder, Tersier
  final String benefitFrequency; // Setiap Hari, Beberapa Kali Seminggu, Jarang
  final String recommendationResult; // Worth It, Consider, Not Worth It
  final double budgetRatio; // (price / budget) * 100
  final String reasonText;
  final DateTime createdAt;

  PurchaseAnalysis({
    required this.id,
    this.userId,
    required this.itemName,
    required this.price,
    required this.budget,
    required this.needLevel,
    required this.benefitFrequency,
    required this.recommendationResult,
    required this.budgetRatio,
    required this.reasonText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'item_name': itemName,
      'price': price,
      'budget': budget,
      'need_level': needLevel,
      'benefit_frequency': benefitFrequency,
      'recommendation_result': recommendationResult,
      'budget_ratio': budgetRatio,
      'reason_text': reasonText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PurchaseAnalysis.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return PurchaseAnalysis(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      itemName: map['item_name'] ?? '',
      price: parseDouble(map['price']),
      budget: parseDouble(map['budget']),
      needLevel: map['need_level'] ?? 'Sekunder',
      benefitFrequency: map['benefit_frequency'] ?? 'Beberapa Kali Seminggu',
      recommendationResult: map['recommendation_result'] ?? 'Consider',
      budgetRatio: parseDouble(map['budget_ratio']),
      reasonText: map['reason_text'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PurchaseAnalysis.fromJson(String source) =>
      PurchaseAnalysis.fromMap(json.decode(source));
}
