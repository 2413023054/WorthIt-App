import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_units.dart';
import '../../../core/models/price_comparison.dart';
import '../../../core/models/product_item.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../logic/unit_converter.dart';

class ComparisonScreen extends StatefulWidget {
  final LocalStorageService localStorage;

  const ComparisonScreen({super.key, required this.localStorage});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();

  String _selectedCategory = AppUnits.categoryWeight;
  bool _isSaving = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  // Controllers for dynamic products
  final List<ProductCardData> _productCards = [];

  @override
  void initState() {
    super.initState();
    _initDefaultProducts();
  }

  void _initDefaultProducts() {
    _productCards.clear();
    final defaultUnit = AppUnits.getUnitsForCategory(_selectedCategory).first;

    // Default 2 products
    _productCards.add(ProductCardData(
      nameController: TextEditingController(text: "Produk A"),
      priceController: TextEditingController(),
      sizeController: TextEditingController(),
      unit: defaultUnit,
    ));

    _productCards.add(ProductCardData(
      nameController: TextEditingController(text: "Produk B"),
      priceController: TextEditingController(),
      sizeController: TextEditingController(),
      unit: defaultUnit,
    ));
  }

  void _onCategoryChanged(String newCategory) {
    if (_selectedCategory == newCategory) return;
    setState(() {
      _selectedCategory = newCategory;
      final newDefaultUnit = AppUnits.getUnitsForCategory(newCategory).first;
      for (var card in _productCards) {
        card.unit = newDefaultUnit;
      }
    });
  }

  void _addProduct() {
    if (_productCards.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maksimal perbandingan 4 produk sekaligus.")),
      );
      return;
    }

    final char = String.fromCharCode(65 + _productCards.length); // C, D
    final defaultUnit = AppUnits.getUnitsForCategory(_selectedCategory).first;

    setState(() {
      _productCards.add(ProductCardData(
        nameController: TextEditingController(text: "Produk $char"),
        priceController: TextEditingController(),
        sizeController: TextEditingController(),
        unit: defaultUnit,
      ));
    });
  }

  void _removeProduct(int index) {
    if (_productCards.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal harus ada 2 produk untuk dibandingkan.")),
      );
      return;
    }
    setState(() {
      final removed = _productCards.removeAt(index);
      removed.dispose();
    });
  }

  void _handleCompare() {
    if (!_formKey.currentState!.validate()) return;

    final List<ProductItem> items = [];

    for (var card in _productCards) {
      final double price = double.tryParse(card.priceController.text.trim()) ?? 0.0;
      final double size = double.tryParse(card.sizeController.text.trim()) ?? 0.0;

      items.add(ProductItem(
        name: card.nameController.text.trim(),
        price: price,
        size: size,
        unit: card.unit,
      ));
    }

    final double userBudget =
        double.tryParse(_budgetController.text.trim()) ?? 0.0;

    final result = UnitConverter.compareProducts(
      category: _selectedCategory,
      inputProducts: items,
      userBudget: userBudget,
    );

    final comparisonModel = UnitConverter.createComparisonModel(
      category: _selectedCategory,
      inputProducts: items,
      userBudget: userBudget,
      userId: SupabaseService.currentUser?.id,
    );

    _showComparisonResultSheet(result, comparisonModel);
  }

  void _showComparisonResultSheet(
    ComparisonCalculationResult result,
    PriceComparison model,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Winner Icon & Badge
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.worthItGreen.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.worthItGreen,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        "Produk Paling Hemat",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.worthItGreen,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        result.winner.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Summary Card
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: (isDark
                                ? AppColors.secondaryCyan
                                : AppColors.primaryIndigo)
                            .withOpacity(0.08),
                        child: Text(
                          result.savingsSummary,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Smart Budget Warning (if any)
                      if (result.smartBudgetWarning != null) ...[
                        CustomCard(
                          padding: const EdgeInsets.all(14),
                          borderColor: AppColors.considerAmber,
                          backgroundColor:
                              AppColors.considerAmber.withOpacity(0.1),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.considerAmber,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  result.smartBudgetWarning!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Comparison List of all items
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Peringkat Harga Satuan (${result.referenceUnitDisplay}):",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...result.evaluatedProducts.map((p) {
                        double multiplier = 1.0;
                        if (_selectedCategory == AppUnits.categoryWeight ||
                            _selectedCategory == AppUnits.categoryVolume) {
                          multiplier = 1000.0;
                        }
                        final refPrice = p.normalizedPrice * multiplier;

                        return CustomCard(
                          padding: const EdgeInsets.all(14),
                          borderColor: p.isWinner
                              ? AppColors.worthItGreen
                              : Colors.transparent,
                          child: Row(
                            children: [
                              if (p.isWinner)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: const BoxDecoration(
                                    color: AppColors.worthItLightGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.worthItGreen,
                                    size: 16,
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      "${_currencyFormat.format(p.price)} / ${p.size} ${p.unit}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${_currencyFormat.format(refPrice)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: p.isWinner
                                          ? AppColors.worthItGreen
                                          : (isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary),
                                    ),
                                  ),
                                  Text(
                                    result.referenceUnitDisplay,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),

                      // Save Button
                      CustomButton(
                        text: _isSaving ? "Menyimpan..." : "Simpan Hasil Komparasi",
                        icon: Icons.bookmark_added_rounded,
                        isLoading: _isSaving,
                        onPressed: () async {
                          setModalState(() => _isSaving = true);
                          await _saveComparisonRecord(model);
                          setModalState(() => _isSaving = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Tutup"),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveComparisonRecord(PriceComparison comp) async {
    try {
      if (SupabaseService.isLoggedIn) {
        await SupabaseService.savePriceComparison(comp);
      } else {
        await widget.localStorage.saveGuestComparison(comp);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Hasil perbandingan berhasil disimpan ke riwayat!"),
            backgroundColor: AppColors.worthItGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan: $e"),
            backgroundColor: AppColors.notWorthItRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    for (var card in _productCards) {
      card.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bandingkan Harga"),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: "Reset Form",
            onPressed: () {
              setState(() {
                _budgetController.clear();
                _initDefaultProducts();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Selector
                Text(
                  "Pilih Kategori Satuan Produk",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: AppUnits.categoryWeight,
                      label: Text("Berat"),
                      icon: Icon(Icons.scale_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: AppUnits.categoryVolume,
                      label: Text("Volume"),
                      icon: Icon(Icons.water_drop_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: AppUnits.categoryQuantity,
                      label: Text("Jumlah"),
                      icon: Icon(Icons.pin_outlined, size: 16),
                    ),
                  ],
                  selected: {_selectedCategory},
                  onSelectionChanged: (Set<String> newSelection) {
                    _onCategoryChanged(newSelection.first);
                  },
                ),
                const SizedBox(height: 18),

                // Optional User Budget
                CustomTextField(
                  controller: _budgetController,
                  label: "Anggaran Belanjamu (Opsional)",
                  hint: "Misal: 50000 (Untuk cek peringatan budget)",
                  prefixText: "Rp",
                  isNumeric: true,
                  prefixIcon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 22),

                // Product Cards List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Daftar Produk yang Dibandingkan",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      "${_productCards.length} / 4",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...List.generate(_productCards.length, (index) {
                  final card = _productCards[index];
                  final units = AppUnits.getUnitsForCategory(_selectedCategory);

                  return CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Produk #${index + 1}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.secondaryCyan
                                    : AppColors.primaryIndigo,
                              ),
                            ),
                            if (_productCards.length > 2)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.notWorthItRed,
                                  size: 20,
                                ),
                                onPressed: () => _removeProduct(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Nama Produk
                        CustomTextField(
                          controller: card.nameController,
                          label: "Nama / Merek Produk",
                          hint: "Misal: Gula Merek A",
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Nama produk wajib diisi";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Harga & Ukuran
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Harga
                            Expanded(
                              flex: 3,
                              child: CustomTextField(
                                controller: card.priceController,
                                label: "Harga Beli",
                                hint: "17000",
                                prefixText: "Rp",
                                isNumeric: true,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return "Wajib diisi";
                                  }
                                  final num = double.tryParse(val);
                                  if (num == null || num <= 0) {
                                    return "Harus > 0";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Ukuran
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: card.sizeController,
                                label: "Isi / Ukuran",
                                hint: "1",
                                isDecimal: true,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return "Wajib diisi";
                                  }
                                  final num = double.tryParse(val);
                                  if (num == null || num <= 0) {
                                    return "Harus > 0";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Satuan Dropdown
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Satuan",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceElevated
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: units.contains(card.unit)
                                            ? card.unit
                                            : units.first,
                                        isExpanded: true,
                                        icon: const Icon(
                                            Icons.keyboard_arrow_down_rounded),
                                        items: units.map((u) {
                                          return DropdownMenuItem<String>(
                                            value: u,
                                            child: Text(
                                              u,
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => card.unit = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),

                // Button Tambah Produk
                if (_productCards.length < 4)
                  CustomButton(
                    text: AppStrings.btnAddProduct,
                    isSecondary: true,
                    icon: Icons.add_rounded,
                    onPressed: _addProduct,
                  ),
                const SizedBox(height: 24),

                // Button Compare
                CustomButton(
                  text: AppStrings.btnCompare,
                  icon: Icons.compare_rounded,
                  onPressed: _handleCompare,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCardData {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController sizeController;
  String unit;

  ProductCardData({
    required this.nameController,
    required this.priceController,
    required this.sizeController,
    required this.unit,
  });

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    sizeController.dispose();
  }
}
