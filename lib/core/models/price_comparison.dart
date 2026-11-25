import 'dart:convert';
import 'product_item.dart';

class PriceComparison {
  final String id;
  final String? userId;
  final String comparisonCategory; // Berat, Volume, Jumlah
  final double userBudget;
  final String winnerProductName;
  final double winnerUnitPrice;
  final String referenceUnit; // 'per gram', 'per kg', 'per ml', 'per liter', 'per pcs'
  final double savingsPercentage;
  final List<ProductItem> products;
  final String? smartBudgetWarning;
  final DateTime createdAt;

  PriceComparison({
    required this.id,
    this.userId,
    required this.comparisonCategory,
    required this.userBudget,
    required this.winnerProductName,
    required this.winnerUnitPrice,
    required this.referenceUnit,
    required this.savingsPercentage,
    required this.products,
    this.smartBudgetWarning,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'comparison_category': comparisonCategory,
      'user_budget': userBudget,
      'winner_product_name': winnerProductName,
      'winner_unit_price': winnerUnitPrice,
      'reference_unit': referenceUnit,
      'savings_percentage': savingsPercentage,
      'products_data': products.map((p) => p.toMap()).toList(),
      if (smartBudgetWarning != null)
        'smart_budget_warning': smartBudgetWarning,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PriceComparison.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    List<ProductItem> prods = [];
    if (map['products_data'] != null) {
      var list = map['products_data'];
      if (list is String) {
        try {
          list = json.decode(list);
        } catch (_) {}
      }
      if (list is List) {
        prods = list.map((item) => ProductItem.fromMap(item)).toList();
      }
    }

    return PriceComparison(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      comparisonCategory: map['comparison_category'] ?? 'Berat',
      userBudget: parseDouble(map['user_budget']),
      winnerProductName: map['winner_product_name'] ?? '',
      winnerUnitPrice: parseDouble(map['winner_unit_price']),
      referenceUnit: map['reference_unit'] ?? 'per satuan',
      savingsPercentage: parseDouble(map['savings_percentage']),
      products: prods,
      smartBudgetWarning: map['smart_budget_warning'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PriceComparison.fromJson(String source) =>
      PriceComparison.fromMap(json.decode(source));
}
