class AppUnits {
  // Categories
  static const String categoryWeight = "Berat";
  static const String categoryVolume = "Volume";
  static const String categoryQuantity = "Jumlah";

  static const List<String> categories = [
    categoryWeight,
    categoryVolume,
    categoryQuantity,
  ];

  // Weight units and their factor to base unit: Gram (g)
  static const Map<String, double> weightUnits = {
    'Gram (g)': 1.0,
    'Kilogram (kg)': 1000.0,
    'Miligram (mg)': 0.001,
  };

  // Volume units and their factor to base unit: Mililiter (ml)
  static const Map<String, double> volumeUnits = {
    'Mililiter (ml)': 1.0,
    'Liter (l)': 1000.0,
  };

  // Quantity units (base unit: pcs)
  static const Map<String, double> quantityUnits = {
    'Pcs / Buah': 1.0,
    'Sachet': 1.0,
    'Butir': 1.0,
    'Botol': 1.0,
    'Lembar': 1.0,
    'Bungkus / Pack': 1.0,
  };

  static List<String> getUnitsForCategory(String category) {
    switch (category) {
      case categoryWeight:
        return weightUnits.keys.toList();
      case categoryVolume:
        return volumeUnits.keys.toList();
      case categoryQuantity:
        return quantityUnits.keys.toList();
      default:
        return [];
    }
  }

  static String getBaseUnitName(String category) {
    switch (category) {
      case categoryWeight:
        return "gram";
      case categoryVolume:
        return "ml";
      case categoryQuantity:
        return "unit";
      default:
        return "satuan";
    }
  }

  static String getDisplayReferenceUnit(String category) {
    switch (category) {
      case categoryWeight:
        return "kg";
      case categoryVolume:
        return "liter";
      case categoryQuantity:
        return "pcs";
      default:
        return "satuan";
    }
  }

  static double getFactor(String category, String unitName) {
    switch (category) {
      case categoryWeight:
        return weightUnits[unitName] ?? 1.0;
      case categoryVolume:
        return volumeUnits[unitName] ?? 1.0;
      case categoryQuantity:
        return quantityUnits[unitName] ?? 1.0;
      default:
        return 1.0;
    }
  }
}
