import 'package:flutter_test/flutter_test.dart';
import 'package:worthit/core/constants/app_strings.dart';
import 'package:worthit/core/constants/app_units.dart';
import 'package:worthit/core/models/product_item.dart';
import 'package:worthit/features/comparison/logic/unit_converter.dart';
import 'package:worthit/features/feasibility/logic/feasibility_calculator.dart';

void main() {
  group('Feasibility Calculator Tests', () {
    test('Over budget should return Not Worth It', () {
      final res = FeasibilityCalculator.calculate(
        price: 150000,
        budget: 100000,
        needLevel: 'Primer',
        benefitFrequency: 'Setiap Hari',
      );
      expect(res.status, AppStrings.notWorthIt);
      expect(res.budgetRatio, 150.0);
    });

    test('Primer under budget should return Worth It', () {
      final res = FeasibilityCalculator.calculate(
        price: 50000,
        budget: 100000,
        needLevel: 'Primer',
        benefitFrequency: 'Setiap Hari',
      );
      expect(res.status, AppStrings.worthIt);
      expect(res.budgetRatio, 50.0);
    });

    test('Sekunder with low ratio should return Worth It', () {
      final res = FeasibilityCalculator.calculate(
        price: 30000,
        budget: 100000,
        needLevel: 'Sekunder',
        benefitFrequency: 'Beberapa Kali Seminggu',
      );
      expect(res.status, AppStrings.worthIt);
    });

    test('Tersier with high ratio should return Not Worth It', () {
      final res = FeasibilityCalculator.calculate(
        price: 60000,
        budget: 100000,
        needLevel: 'Tersier',
        benefitFrequency: 'Jarang',
      );
      expect(res.status, AppStrings.notWorthIt);
    });
  });

  group('Smart Price Comparison & Unit Conversion Tests', () {
    test('Sugar comparison: 1 kg (Rp17.000) vs 500 g (Rp10.000)', () {
      // Sesuai contoh pada soal:
      // Produk A: 1 kg (Rp17.000) -> Rp17 / gram
      // Produk B: 500 g (Rp10.000) -> Rp20 / gram
      final products = [
        ProductItem(
          name: 'Gula A',
          price: 17000,
          size: 1,
          unit: 'Kilogram (kg)',
        ),
        ProductItem(
          name: 'Gula B',
          price: 10000,
          size: 500,
          unit: 'Gram (g)',
        ),
      ];

      final result = UnitConverter.compareProducts(
        category: AppUnits.categoryWeight,
        inputProducts: products,
      );

      expect(result.winner.name, 'Gula A');
      expect(result.winner.normalizedPrice, 17.0);
      expect(result.savingsPercentage, 15.0); // (20 - 17) / 20 = 15%
    });

    test('Volume comparison: 2 liter vs 1000 ml', () {
      final products = [
        ProductItem(
          name: 'Minyak A',
          price: 30000,
          size: 2,
          unit: 'Liter (l)',
        ),
        ProductItem(
          name: 'Minyak B',
          price: 16000,
          size: 1000,
          unit: 'Mililiter (ml)',
        ),
      ];

      final result = UnitConverter.compareProducts(
        category: AppUnits.categoryVolume,
        inputProducts: products,
      );

      // Minyak A: Rp30.000 / 2000 ml = Rp15 / ml
      // Minyak B: Rp16.000 / 1000 ml = Rp16 / ml
      expect(result.winner.name, 'Minyak A');
      expect(result.winner.normalizedPrice, 15.0);
    });

    test('Smart Budget Alert when winner exceeds budget', () {
      final products = [
        ProductItem(
          name: 'Beras Karung 25 kg',
          price: 350000, // Rp14.000/kg
          size: 25,
          unit: 'Kilogram (kg)',
        ),
        ProductItem(
          name: 'Beras 5 kg',
          price: 80000, // Rp16.000/kg
          size: 5,
          unit: 'Kilogram (kg)',
        ),
      ];

      final result = UnitConverter.compareProducts(
        category: AppUnits.categoryWeight,
        inputProducts: products,
        userBudget: 100000, // Anggaran hanya Rp100.000
      );

      // Winner secara harga satuan adalah Beras 25 kg, tapi harganya Rp350.000 > budget Rp100.000
      expect(result.winner.name, 'Beras Karung 25 kg');
      expect(result.smartBudgetWarning, isNotNull);
      expect(result.smartBudgetWarning, contains('melampaui anggaran'));
    });
  });
}
