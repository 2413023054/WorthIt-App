import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/purchase_analysis.dart';
import '../../../core/models/price_comparison.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_card.dart';

class DashboardScreen extends StatefulWidget {
  final LocalStorageService localStorage;
  final Function(int) onNavigateToTab;

  const DashboardScreen({
    super.key,
    required this.localStorage,
    required this.onNavigateToTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String _userName = "Sobat Hemat";
  List<PurchaseAnalysis> _recentAnalyses = [];
  List<PriceComparison> _recentComparisons = [];
  int _totalAnalyses = 0;
  int _totalComparisons = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      if (SupabaseService.isLoggedIn) {
        final profile = await SupabaseService.fetchUserProfile();
        _userName = profile?.fullName ?? "Sobat Hemat";

        final cloudAnalyses = await SupabaseService.fetchPurchaseAnalyses();
        final cloudComparisons = await SupabaseService.fetchPriceComparisons();

        _recentAnalyses = cloudAnalyses.take(3).toList();
        _recentComparisons = cloudComparisons.take(3).toList();
        _totalAnalyses = cloudAnalyses.length;
        _totalComparisons = cloudComparisons.length;
      } else {
        _userName = "Sobat Hemat (Tamu)";
        final localAnalyses = widget.localStorage.getGuestAnalyses();
        final localComparisons = widget.localStorage.getGuestComparisons();

        _recentAnalyses = localAnalyses.take(3).toList();
        _recentComparisons = localComparisons.take(3).toList();
        _totalAnalyses = localAnalyses.length;
        _totalComparisons = localComparisons.length;
      }
    } catch (e) {
      print("Error loading dashboard data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppStrings.worthIt:
        return AppColors.worthItGreen;
      case AppStrings.consider:
        return AppColors.considerAmber;
      case AppStrings.notWorthIt:
        return AppColors.notWorthItRed;
      default:
        return AppColors.primaryIndigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.secondaryCyan : AppColors.primaryIndigo)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.savings_rounded,
                color: isDark ? AppColors.secondaryCyan : AppColors.primaryIndigo,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              AppStrings.appName,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Muat Ulang Data",
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: "Profil Akun",
            onPressed: () => widget.onNavigateToTab(4), // Tab Profil
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.cardAccentGradient
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryIndigo.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Halo, $_userName! 👋",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Mau belanja apa hari ini? Pastikan keputusan belanjamu bijak dan bebas penyesalan.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Section
                    Text(
                      "Aksi Cepat",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Quick Action 1: Analisis Kelayakan
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.onNavigateToTab(1), // Tab Feasibility
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.worthItGreen
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.insights_rounded,
                                      color: AppColors.worthItGreen,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    "Analisis Beli",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Cek apakah barang layak dibeli",
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
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Quick Action 2: Bandingkan Harga
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.onNavigateToTab(2), // Tab Comparison
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentCyan
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.compare_arrows_rounded,
                                      color: AppColors.accentCyan,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    "Banding Harga",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Cari produk paling hemat",
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ringkasan Statistik
                    Text(
                      "Statistik Aktivitasmu",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Analisis",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "$_totalAnalyses Keputusan",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.secondaryCyan
                                        : AppColors.primaryIndigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Komparasi",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "$_totalComparisons Produk",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.secondaryCyan
                                        : AppColors.primaryIndigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Aktivitas Terakhir
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Aktivitas Terkini",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateToTab(3), // Tab History
                          child: const Text("Lihat Semua"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_recentAnalyses.isEmpty && _recentComparisons.isEmpty)
                      CustomCard(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.hourglass_empty_rounded,
                                size: 36,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Belum ada aktivitas",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Mulai analisis kelayakan atau bandingkan harga produk pertamamu!",
                                textAlign: TextAlign.center,
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
                      )
                    else ...[
                      // Recent Analyses
                      ..._recentAnalyses.map((item) {
                        final color = _getStatusColor(item.recommendationResult);
                        return CustomCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => widget.onNavigateToTab(3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 14),
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
                                      "${_currencyFormat.format(item.price)} • ${item.needLevel}",
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.recommendationResult,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Recent Comparisons
                      ..._recentComparisons.map((comp) {
                        return CustomCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => widget.onNavigateToTab(3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyan,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Komparasi ${comp.comparisonCategory}: ${comp.winnerProductName}",
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
                                      "Paling Hemat: ${comp.winnerProductName} (${comp.savingsPercentage}% lebih hemat)",
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
                              const Icon(
                                Icons.workspace_premium_rounded,
                                color: AppColors.accentCyan,
                                size: 24,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
