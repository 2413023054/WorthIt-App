class ProductItem {
  String name;
  double price;
  double size;
  String unit;
  double normalizedPrice; // Harga per gram, per ml, atau per pcs
  bool isWinner;

  ProductItem({
    required this.name,
    required this.price,
    required this.size,
    required this.unit,
    this.normalizedPrice = 0.0,
    this.isWinner = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'size': size,
      'unit': unit,
      'normalized_price': normalizedPrice,
      'is_winner': isWinner,
    };
  }

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    return ProductItem(
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      size: (map['size'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      normalizedPrice: (map['normalized_price'] as num?)?.toDouble() ?? 0.0,
      isWinner: map['is_winner'] ?? false,
    );
  }
}
