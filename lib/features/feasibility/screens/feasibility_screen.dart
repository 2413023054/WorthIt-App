import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/purchase_analysis.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../logic/feasibility_calculator.dart';

class FeasibilityScreen extends StatefulWidget {
  final LocalStorageService localStorage;

  const FeasibilityScreen({super.key, required this.localStorage});

  @override
  State<FeasibilityScreen> createState() => _FeasibilityScreenState();
}

class _FeasibilityScreenState extends State<FeasibilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _budgetController = TextEditingController();

  String _needLevel = "Primer"; // Primer, Sekunder, Tersier
  String _benefitFrequency = "Setiap Hari"; // Setiap Hari, Beberapa Kali Seminggu, Jarang
  bool _isSaving = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _handleAnalyze() {
    if (!_formKey.currentState!.validate()) return;

    final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final double budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    final result = FeasibilityCalculator.calculate(
      price: price,
      budget: budget,
      needLevel: _needLevel,
      benefitFrequency: _benefitFrequency,
    );

    final analysis = FeasibilityCalculator.createAnalysisModel(
      itemName: _nameController.text.trim(),
      price: price,
      budget: budget,
      needLevel: _needLevel,
      benefitFrequency: _benefitFrequency,
      userId: SupabaseService.currentUser?.id,
    );

    _showResultDialog(result, analysis);
  }

  void _showResultDialog(FeasibilityResult result, PurchaseAnalysis analysis) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;

    switch (result.status) {
      case AppStrings.worthIt:
        statusColor = AppColors.worthItGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case AppStrings.consider:
        statusColor = AppColors.considerAmber;
        statusIcon = Icons.help_outline_rounded;
        break;
      case AppStrings.notWorthIt:
      default:
        statusColor = AppColors.notWorthItRed;
        statusIcon = Icons.cancel_rounded;
        break;
    }

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
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Badge Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 48),
                  ),
                  const SizedBox(height: 14),

                  // Status Text
                  Text(
                    result.status,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Ratio
                  Text(
                    "Menyerap ${result.budgetRatio.toStringAsFixed(1)}% dari Anggaranmu",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reason Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    child: Text(
                      result.reason,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  CustomButton(
                    text: _isSaving ? "Menyimpan..." : "Simpan Hasil ke Riwayat",
                    icon: Icons.bookmark_added_rounded,
                    isLoading: _isSaving,
                    onPressed: () async {
                      setModalState(() => _isSaving = true);
                      await _saveAnalysisRecord(analysis);
                      setModalState(() => _isSaving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Close / Reset
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resetForm();
                    },
                    child: const Text("Tutup & Hitung Ulang"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveAnalysisRecord(PurchaseAnalysis analysis) async {
    try {
      if (SupabaseService.isLoggedIn) {
        await SupabaseService.savePurchaseAnalysis(analysis);
      } else {
        await widget.localStorage.saveGuestAnalysis(analysis);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Hasil analisis berhasil disimpan ke riwayat!"),
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

  void _resetForm() {
    _nameController.clear();
    _priceController.clear();
    _budgetController.clear();
    setState(() {
      _needLevel = "Primer";
      _benefitFrequency = "Setiap Hari";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analisis Kelayakan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: "Bersihkan Form",
            onPressed: _resetForm,
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
                // Info Banner
                CustomCard(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: (isDark
                          ? AppColors.secondaryCyan
                          : AppColors.primaryIndigo)
                      .withOpacity(0.08),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: isDark
                            ? AppColors.secondaryCyan
                            : AppColors.primaryIndigo,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Isi detail barang dan anggaranmu untuk mengetahui apakah pembelian ini bijak atau impulsif.",
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
                const SizedBox(height: 20),

                // Nama Barang
                CustomTextField(
                  controller: _nameController,
                  label: "Nama Barang / Produk",
                  hint: "Misal: Sepatu Olahraga, Laptop Baru, Kopi Kafe",
                  prefixIcon: Icons.shopping_bag_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Nama barang wajib diisi";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Harga Barang
                CustomTextField(
                  controller: _priceController,
                  label: "Harga Barang",
                  hint: "500000",
                  prefixText: "Rp",
                  isNumeric: true,
                  prefixIcon: Icons.payments_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Harga barang wajib diisi";
                    }
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) {
                      return "Masukkan harga yang valid (lebih dari 0)";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Anggaran yang Dimiliki
                CustomTextField(
                  controller: _budgetController,
                  label: "Anggaran Belanja yang Kamu Miliki",
                  hint: "1000000",
                  prefixText: "Rp",
                  isNumeric: true,
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Anggaran wajib diisi";
                    }
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) {
                      return "Masukkan anggaran yang valid (lebih dari 0)";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // Tingkat Kebutuhan
                Text(
                  "Tingkat Kebutuhan",
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
                      value: "Primer",
                      label: Text("Primer / Urgent"),
                      icon: Icon(Icons.emergency_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: "Sekunder",
                      label: Text("Sekunder"),
                      icon: Icon(Icons.star_outline_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: "Tersier",
                      label: Text("Tersier / Ingin"),
                      icon: Icon(Icons.celebration_outlined, size: 16),
                    ),
                  ],
                  selected: {_needLevel},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _needLevel = newSelection.first);
                  },
                ),
                const SizedBox(height: 22),

                // Frekuensi Penggunaan
                Text(
                  "Seberapa Sering Akan Digunakan?",
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
                      value: "Setiap Hari",
                      label: Text("Rutin Harian"),
                      icon: Icon(Icons.repeat_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: "Beberapa Kali Seminggu",
                      label: Text("Mingguan"),
                      icon: Icon(Icons.calendar_today_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: "Jarang",
                      label: Text("Jarang / Sekali"),
                      icon: Icon(Icons.event_busy_rounded, size: 16),
                    ),
                  ],
                  selected: {_benefitFrequency},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _benefitFrequency = newSelection.first);
                  },
                ),
                const SizedBox(height: 32),

                // Tombol Eksekusi
                CustomButton(
                  text: AppStrings.btnAnalyze,
                  icon: Icons.analytics_rounded,
                  onPressed: _handleAnalyze,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
