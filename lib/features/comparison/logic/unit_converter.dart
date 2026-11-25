import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_units.dart';
import '../../../core/models/price_comparison.dart';
import '../../../core/models/product_item.dart';

class ComparisonCalculationResult {
  final List<ProductItem> evaluatedProducts;
  final ProductItem winner;
  final double savingsPercentage;
  final String savingsSummary;
  final String referenceUnitDisplay;
  final String? smartBudgetWarning;

  ComparisonCalculationResult({
    required this.evaluatedProducts,
    required this.winner,
    required this.savingsPercentage,
    required this.savingsSummary,
    required this.referenceUnitDisplay,
    this.smartBudgetWarning,
  });
}

class UnitConverter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static ComparisonCalculationResult compareProducts({
    required String category,
    required List<ProductItem> inputProducts,
    double userBudget = 0.0,
  }) {
    if (inputProducts.isEmpty) {
      throw Exception("Minimal masukkan 2 produk untuk dibandingkan.");
    }

    // 1. Hitung harga satuan ternormalisasi untuk setiap produk
    final List<ProductItem> calculated = [];

    for (var prod in inputProducts) {
      final double factor = AppUnits.getFactor(category, prod.unit);
      final double totalBaseUnits = prod.size * factor;

      double normalizedPrice = 0.0;
      if (totalBaseUnits > 0) {
        normalizedPrice = prod.price / totalBaseUnits;
      }

      calculated.add(ProductItem(
        name: prod.name.trim().isEmpty ? "Produk" : prod.name.trim(),
        price: prod.price,
        size: prod.size,
        unit: prod.unit,
        normalizedPrice: normalizedPrice,
        isWinner: false,
      ));
    }

    // 2. Temukan produk dengan harga satuan terendah (winner) & tertinggi
    calculated.sort((a, b) => a.normalizedPrice.compareTo(b.normalizedPrice));

    final winner = calculated.first;
    winner.isWinner = true;

    final mostExpensive = calculated.last;

    // 3. Hitung persentase penghematan
    double savingsPct = 0.0;
    if (mostExpensive.normalizedPrice > 0 &&
        mostExpensive.normalizedPrice != winner.normalizedPrice) {
      savingsPct = ((mostExpensive.normalizedPrice - winner.normalizedPrice) /
              mostExpensive.normalizedPrice) *
          100;
    }

    // 4. Buat deskripsi perbandingan dalam satuan acuan
    // Berat -> per kg (1000g), Volume -> per liter (1000ml), Jumlah -> per pcs (1 unit)
    double referenceMultiplier = 1.0;
    String refUnitLabel = "per ${AppUnits.getBaseUnitName(category)}";

    if (category == AppUnits.categoryWeight) {
      referenceMultiplier = 1000.0;
      refUnitLabel = "per kg";
    } else if (category == AppUnits.categoryVolume) {
      referenceMultiplier = 1000.0;
      refUnitLabel = "per liter";
    } else {
      referenceMultiplier = 1.0;
      refUnitLabel = "per pcs";
    }

    final double winnerRefPrice = winner.normalizedPrice * referenceMultiplier;
    final double expensiveRefPrice =
        mostExpensive.normalizedPrice * referenceMultiplier;
    final double diffRefNominal = expensiveRefPrice - winnerRefPrice;

    String savingsSummary;
    if (calculated.length >= 2 && savingsPct > 0) {
      final diffNominalFormatted = _currencyFormat.format(diffRefNominal);
      savingsSummary =
          "${winner.name} lebih hemat ${savingsPct.toStringAsFixed(1)}% (selisih $diffNominalFormatted $refUnitLabel) dibandingkan ${mostExpensive.name}.";
    } else {
      savingsSummary =
          "Seluruh produk memiliki harga satuan yang sama atau setara.";
    }

    // 5. Smart Budget Warning
    String? budgetWarning;
    if (userBudget > 0 && winner.price > userBudget) {
      final formattedPrice = _currencyFormat.format(winner.price);
      final formattedBudget = _currencyFormat.format(userBudget);
      budgetWarning =
          "Perhatian: Meskipun harga satuan ${winner.name} paling hemat, total harga belinya ($formattedPrice) melampaui anggaran yang kamu sediakan ($formattedBudget). Pastikan kamu memang membutuhkan kuantitas sebanyak ini.";
    }

    return ComparisonCalculationResult(
      evaluatedProducts: calculated,
      winner: winner,
      savingsPercentage: double.parse(savingsPct.toStringAsFixed(1)),
      savingsSummary: savingsSummary,
      referenceUnitDisplay: refUnitLabel,
      smartBudgetWarning: budgetWarning,
    );
  }

  static PriceComparison createComparisonModel({
    required String category,
    required List<ProductItem> inputProducts,
    double userBudget = 0.0,
    String? userId,
  }) {
    final result = compareProducts(
      category: category,
      inputProducts: inputProducts,
      userBudget: userBudget,
    );

    return PriceComparison(
      id: const Uuid().v4(),
      userId: userId,
      comparisonCategory: category,
      userBudget: userBudget,
      winnerProductName: result.winner.name,
      winnerUnitPrice: result.winner.normalizedPrice,
      referenceUnit: result.referenceUnitDisplay,
      savingsPercentage: result.savingsPercentage,
      products: result.evaluatedProducts,
      smartBudgetWarning: result.smartBudgetWarning,
      createdAt: DateTime.now(),
    );
  }
}
