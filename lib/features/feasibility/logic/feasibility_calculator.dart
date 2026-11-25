import 'package:uuid/uuid.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/purchase_analysis.dart';

class FeasibilityResult {
  final String status; // Worth It, Consider, Not Worth It
  final double budgetRatio;
  final String reason;

  FeasibilityResult({
    required this.status,
    required this.budgetRatio,
    required this.reason,
  });
}

class FeasibilityCalculator {
  static FeasibilityResult calculate({
    required double price,
    required double budget,
    required String needLevel,
    required String benefitFrequency,
  }) {
    if (budget <= 0) {
      return FeasibilityResult(
        status: AppStrings.notWorthIt,
        budgetRatio: 100.0,
        reason:
            "Anggaran yang dimasukkan tidak valid atau Rp0. Pembelian tanpa alokasi anggaran tidak disarankan.",
      );
    }

    final double ratio = (price / budget) * 100;
    final String formattedRatio = ratio.toStringAsFixed(1);

    if (price > budget) {
      return FeasibilityResult(
        status: AppStrings.notWorthIt,
        budgetRatio: ratio,
        reason:
            "Harga barang ini melampaui anggaran yang kamu miliki ($formattedRatio% dari budget). Memaksakan pembelian ini berisiko mengganggu kestabilan keuanganmu. Tunda sampai dana mencukupi.",
      );
    }

    // Level: Primer / Mendesak
    if (needLevel == "Primer") {
      return FeasibilityResult(
        status: AppStrings.worthIt,
        budgetRatio: ratio,
        reason:
            "Barang ini adalah kebutuhan primer/mendesak dan berada aman dalam batas anggaranmu ($formattedRatio%). Sangat layak untuk dibeli demi menunjang kebutuhan pokokmu.",
      );
    }

    // Level: Sekunder / Penting
    if (needLevel == "Sekunder") {
      if (ratio <= 50.0 || benefitFrequency == "Setiap Hari") {
        return FeasibilityResult(
          status: AppStrings.worthIt,
          budgetRatio: ratio,
          reason:
              "Kebutuhan penting dengan porsi anggaran terukur ($formattedRatio%) dan memiliki frekuensi penggunaan yang rutin. Keputusan pembelian ini rasional dan menguntungkan.",
        );
      } else if (ratio <= 85.0) {
        return FeasibilityResult(
          status: AppStrings.consider,
          budgetRatio: ratio,
          reason:
              "Barang ini bermanfaat, tetapi menyerap $formattedRatio% dari total anggaranmu. Disarankan mencari alternatif yang lebih terjangkau atau pastikan tidak ada pos pengeluaran lain yang terabaikan.",
        );
      } else {
        return FeasibilityResult(
          status: AppStrings.notWorthIt,
          budgetRatio: ratio,
          reason:
              "Meskipun barang sekunder, harganya menyerap hampir seluruh anggaranmu ($formattedRatio%). Sebaiknya tunda dulu dan utamakan tabungan darurat.",
        );
      }
    }

    // Level: Tersier / Keinginan
    if (needLevel == "Tersier") {
      if (ratio <= 25.0 && benefitFrequency != "Jarang") {
        return FeasibilityResult(
          status: AppStrings.consider,
          budgetRatio: ratio,
          reason:
              "Barang ini adalah keinginan/hiburan yang menyerap porsi kecil dari anggaran ($formattedRatio%). Boleh dibeli sebagai bentuk apresiasi diri (*reward*), selama tabungan utama aman.",
        );
      } else {
        return FeasibilityResult(
          status: AppStrings.notWorthIt,
          budgetRatio: ratio,
          reason:
              "Barang ini bersifat keinginan impulsif dan mengambil porsi anggaran yang signifikan ($formattedRatio%) dengan manfaat yang minim. Sangat disarankan untuk menunda pembelian.",
        );
      }
    }

    // Fallback
    return FeasibilityResult(
      status: AppStrings.consider,
      budgetRatio: ratio,
      reason:
          "Pertimbangkan kembali prioritas kebutuhan dan ketersediaan dana cadanganmu sebelum membeli.",
    );
  }

  static PurchaseAnalysis createAnalysisModel({
    required String itemName,
    required double price,
    required double budget,
    required String needLevel,
    required String benefitFrequency,
    String? userId,
  }) {
    final result = calculate(
      price: price,
      budget: budget,
      needLevel: needLevel,
      benefitFrequency: benefitFrequency,
    );

    return PurchaseAnalysis(
      id: const Uuid().v4(),
      userId: userId,
      itemName: itemName,
      price: price,
      budget: budget,
      needLevel: needLevel,
      benefitFrequency: benefitFrequency,
      recommendationResult: result.status,
      budgetRatio: double.parse(result.budgetRatio.toStringAsFixed(1)),
      reasonText: result.reason,
      createdAt: DateTime.now(),
    );
  }
}
