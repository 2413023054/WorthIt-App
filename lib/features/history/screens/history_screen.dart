import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/purchase_analysis.dart';
import '../../../core/models/price_comparison.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  final LocalStorageService localStorage;

  const HistoryScreen({super.key, required this.localStorage});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  bool _isLoading = true;
  List<PurchaseAnalysis> _analyses = [];
  List<PriceComparison> _comparisons = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);

    try {
      if (SupabaseService.isLoggedIn) {
        _analyses = await SupabaseService.fetchPurchaseAnalyses();
        _comparisons = await SupabaseService.fetchPriceComparisons();
      } else {
        _analyses = widget.localStorage.getGuestAnalyses();
        _comparisons = widget.localStorage.getGuestComparisons();
      }
    } catch (e) {
      print("Error loading history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAnalysis(String id) async {
    try {
      if (SupabaseService.isLoggedIn) {
        await SupabaseService.deletePurchaseAnalysis(id);
      } else {
        await widget.localStorage.deleteGuestAnalysis(id);
      }
      setState(() {
        _analyses.removeWhere((item) => item.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Riwayat analisis dihapus.")),
        );
      }
    } catch (e) {
      print("Error deleting analysis: $e");
    }
  }

  Future<void> _deleteComparison(String id) async {
    try {
      if (SupabaseService.isLoggedIn) {
        await SupabaseService.deletePriceComparison(id);
      } else {
        await widget.localStorage.deleteGuestComparison(id);
      }
      setState(() {
        _comparisons.removeWhere((item) => item.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Riwayat komparasi dihapus.")),
        );
      }
    } catch (e) {
      print("Error deleting comparison: $e");
    }
  }

  void _showClearAllConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Semua Riwayat?"),
        content: const Text(
          "Seluruh data riwayat analisis kelayakan dan komparasi harga akan dihapus secara permanen.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.notWorthItRed,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (SupabaseService.isLoggedIn) {
                for (var a in _analyses) {
                  await SupabaseService.deletePurchaseAnalysis(a.id);
                }
                for (var c in _comparisons) {
                  await SupabaseService.deletePriceComparison(c.id);
                }
              } else {
                await widget.localStorage.clearGuestData();
              }
              _loadHistoryData();
            },
            child: const Text("Hapus Semua", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAnalysisDetail(PurchaseAnalysis item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    switch (item.recommendationResult) {
      case AppStrings.worthIt:
        color = AppColors.worthItGreen;
        break;
      case AppStrings.consider:
        color = AppColors.considerAmber;
        break;
      default:
        color = AppColors.notWorthItRed;
        break;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.recommendationResult,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tanggal: ${_dateFormat.format(item.createdAt)}",
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const Divider(height: 24),
            _buildDetailRow("Harga Barang", _currencyFormat.format(item.price)),
            _buildDetailRow("Anggaranmu", _currencyFormat.format(item.budget)),
            _buildDetailRow("Porsi Anggaran", "${item.budgetRatio}%"),
            _buildDetailRow("Tingkat Kebutuhan", item.needLevel),
            _buildDetailRow("Frekuensi Pakai", item.benefitFrequency),
            const SizedBox(height: 14),
            Text(
              "Alasan & Evaluasi:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.reasonText,
                style: TextStyle(
                  fontSize: 13,
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
    );
  }

  void _showComparisonDetail(PriceComparison comp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.worthItGreen),
            const SizedBox(width: 8),
            Text(
              "Paling Hemat: ${comp.winnerProductName}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kategori: ${comp.comparisonCategory} • ${_dateFormat.format(comp.createdAt)}",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              if (comp.savingsPercentage > 0) ...[
                const SizedBox(height: 8),
                Text(
                  "Hemat ${comp.savingsPercentage}% dibanding produk termahal",
                  style: const TextStyle(
                    color: AppColors.worthItGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
              if (comp.smartBudgetWarning != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.considerAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    comp.smartBudgetWarning!,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
              const Divider(height: 24),
              const Text(
                "Daftar Produk:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...comp.products.map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        p.isWinner
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 16,
                        color: p.isWinner
                            ? AppColors.worthItGreen
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${p.name} (${p.size} ${p.unit})",
                          style: TextStyle(
                            fontWeight: p.isWinner
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        _currencyFormat.format(p.price),
                        style: TextStyle(
                          fontWeight: p.isWinner
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter by search query
    final filteredAnalyses = _analyses.where((a) {
      if (_searchQuery.isEmpty) return true;
      return a.itemName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredComparisons = _comparisons.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.winnerProductName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          c.products
              .any((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    final bool isEmpty =
        filteredAnalyses.isEmpty && filteredComparisons.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Aktivitas"),
        actions: [
          if (!isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: "Hapus Semua Riwayat",
              onPressed: _showClearAllConfirmDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Muat Ulang",
            onPressed: _loadHistoryData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor:
              isDark ? AppColors.secondaryCyan : AppColors.primaryIndigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor:
              isDark ? AppColors.secondaryCyan : AppColors.primaryIndigo,
          tabs: const [
            Tab(text: "Semua"),
            Tab(text: "Analisis Beli"),
            Tab(text: "Komparasi"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
              decoration: InputDecoration(
                hintText: "Cari berdasarkan nama barang...",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Semua
                      _buildCombinedList(
                          filteredAnalyses, filteredComparisons, isDark),

                      // Tab 2: Khusus Analisis
                      _buildAnalysesList(filteredAnalyses, isDark),

                      // Tab 3: Khusus Komparasi
                      _buildComparisonsList(filteredComparisons, isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedList(List<PurchaseAnalysis> analyses,
      List<PriceComparison> comparisons, bool isDark) {
    if (analyses.isEmpty && comparisons.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history_rounded,
        title: "Belum Ada Riwayat",
        subtitle:
            "Seluruh aktivitas analisis dan komparasi harga yang kamu lakukan akan tersimpan di sini.",
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (analyses.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Analisis Kelayakan Beli",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          ...analyses.map((item) => _buildAnalysisCard(item, isDark)),
        ],
        if (comparisons.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Perbandingan Harga Produk",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          ...comparisons.map((comp) => _buildComparisonCard(comp, isDark)),
        ],
      ],
    );
  }

  Widget _buildAnalysesList(List<PurchaseAnalysis> list, bool isDark) {
    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.insights_rounded,
        title: "Belum Ada Riwayat Analisis",
        subtitle: "Lakukan analisis kelayakan belanja untuk melihat riwayat.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _buildAnalysisCard(list[i], isDark),
    );
  }

  Widget _buildComparisonsList(List<PriceComparison> list, bool isDark) {
    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.compare_arrows_rounded,
        title: "Belum Ada Riwayat Komparasi",
        subtitle: "Bandingkan harga produk untuk melihat riwayat.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _buildComparisonCard(list[i], isDark),
    );
  }

  Widget _buildAnalysisCard(PurchaseAnalysis item, bool isDark) {
    Color color;
    switch (item.recommendationResult) {
      case AppStrings.worthIt:
        color = AppColors.worthItGreen;
        break;
      case AppStrings.consider:
        color = AppColors.considerAmber;
        break;
      default:
        color = AppColors.notWorthItRed;
        break;
    }

    return CustomCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showAnalysisDetail(item),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${_currencyFormat.format(item.price)} • Anggaran: ${_currencyFormat.format(item.budget)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateFormat.format(item.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.recommendationResult,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Colors.grey),
            onPressed: () => _deleteAnalysis(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(PriceComparison comp, bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showComparisonDetail(comp),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentCyan,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Paling Hemat: ${comp.winnerProductName}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Kategori ${comp.comparisonCategory} • ${comp.products.length} Produk",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateFormat.format(comp.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (comp.savingsPercentage > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.worthItGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "-${comp.savingsPercentage}%",
                style: const TextStyle(
                  color: AppColors.worthItGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Colors.grey),
            onPressed: () => _deleteComparison(comp.id),
          ),
        ],
      ),
    );
  }
}
