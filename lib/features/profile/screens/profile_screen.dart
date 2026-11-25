import 'package:flutter/material.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../auth/screens/login_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  final LocalStorageService localStorage;
  final Function(ThemeMode) onThemeModeChanged;

  const ProfileScreen({
    super.key,
    required this.localStorage,
    required this.onThemeModeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isSyncing = false;
  UserProfile? _userProfile;
  late String _currentThemeMode;

  @override
  void initState() {
    super.initState();
    _currentThemeMode = widget.localStorage.getThemeMode();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!SupabaseService.isLoggedIn) return;
    setState(() => _isLoading = true);
    try {
      final profile = await SupabaseService.fetchUserProfile();
      setState(() => _userProfile = profile);
    } catch (e) {
      print("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSync() async {
    if (!SupabaseService.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    final localAnalyses = widget.localStorage.getGuestAnalyses();
    final localComparisons = widget.localStorage.getGuestComparisons();

    if (localAnalyses.isEmpty && localComparisons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seluruh data lokal sudah tersinkronkan ke Supabase!"),
          backgroundColor: AppColors.worthItGreen,
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final total = await SupabaseService.syncGuestDataToCloud(
        localAnalyses: localAnalyses,
        localComparisons: localComparisons,
      );

      await widget.localStorage.clearGuestData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil menyinkronkan $total data ke cloud Supabase!"),
            backgroundColor: AppColors.worthItGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal sinkronisasi: $e"),
            backgroundColor: AppColors.notWorthItRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Perlu Masuk Akun"),
        content: const Text(
          "Untuk mencadangkan dan menyinkronkan data riwayat ke Supabase Cloud, Anda harus masuk atau mendaftar akun terlebih dahulu.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Nanti Saja"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(localStorage: widget.localStorage),
                ),
              );
            },
            child: const Text("Masuk / Daftar"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Keluar dari Akun?"),
        content: const Text(
          "Anda akan keluar dari akun ini dan kembali ke antarmuka awal.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.notWorthItRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(localStorage: widget.localStorage),
        ),
        (route) => false,
      );
    }
  }

  void _setTheme(String mode) {
    setState(() => _currentThemeMode = mode);
    widget.localStorage.setThemeMode(mode);

    ThemeMode tm;
    if (mode == 'light') {
      tm = ThemeMode.light;
    } else if (mode == 'dark') {
      tm = ThemeMode.dark;
    } else {
      tm = ThemeMode.system;
    }
    widget.onThemeModeChanged(tm);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn = SupabaseService.isLoggedIn;
    final localAnalyses = widget.localStorage.getGuestAnalyses();
    final localComparisons = widget.localStorage.getGuestComparisons();
    final totalUnsynced = localAnalyses.length + localComparisons.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil & Pengaturan"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Header Card
                  CustomCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? AppColors.cyanGradient
                                : AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isLoggedIn
                                  ? Icons.person_rounded
                                  : Icons.no_accounts_rounded,
                              size: 32,
                              color: isDark
                                  ? AppColors.darkBackground
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLoggedIn
                                    ? (_userProfile?.fullName ?? "Pengguna WorthIt")
                                    : "Mode Tamu (Offline)",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLoggedIn
                                    ? (_userProfile?.email ?? "")
                                    : "Data tersimpan di memori lokal HP",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Guest Mode Banner or Sync Card
                  if (!isLoggedIn) ...[
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      borderColor: AppColors.secondaryCyan,
                      backgroundColor:
                          (isDark ? AppColors.secondaryCyan : AppColors.primaryIndigo)
                              .withOpacity(0.08),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud_upload_outlined,
                                  color: AppColors.accentCyan),
                              const SizedBox(width: 10),
                              Text(
                                "Cadangkan ke Cloud Supabase",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalUnsynced > 0
                                ? "Kamu memiliki $totalUnsynced riwayat lokal yang belum tersinkronkan. Masuk atau daftar akun agar datamu aman di cloud."
                                : "Masuk atau buat akun baru untuk menikmati fitur sinkronisasi cloud antar-perangkat.",
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          CustomButton(
                            text: "Masuk / Daftar Akun",
                            isSecondary: true,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(
                                      localStorage: widget.localStorage),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Sync Card for logged-in user
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.sync_rounded,
                              color: AppColors.worthItGreen, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Sinkronisasi Cloud",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  totalUnsynced > 0
                                      ? "$totalUnsynced data lokal siap disinkronkan"
                                      : "Semua riwayat sudah tersinkronkan",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isSyncing ? null : _handleSync,
                            child: _isSyncing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text("Sinkron"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tema Tampilan (Theme Switcher)
                  Text(
                    "Tampilan & Tema",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _currentThemeMode == 'dark'
                                  ? Icons.dark_mode_rounded
                                  : _currentThemeMode == 'light'
                                      ? Icons.light_mode_rounded
                                      : Icons.brightness_auto_rounded,
                              color: isDark
                                  ? AppColors.secondaryCyan
                                  : AppColors.primaryIndigo,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Mode Tampilan Aplikasi",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'system',
                              label: Text("Otomatis"),
                              icon: Icon(Icons.settings_suggest_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: 'light',
                              label: Text("Terang"),
                              icon: Icon(Icons.wb_sunny_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: 'dark',
                              label: Text("Gelap"),
                              icon: Icon(Icons.nightlight_round, size: 16),
                            ),
                          ],
                          selected: {_currentThemeMode},
                          onSelectionChanged: (Set<String> newSelection) {
                            _setTheme(newSelection.first);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Supabase Configuration Status
                  Text(
                    "Status Koneksi Database",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          SupabaseConfig.isConfigured
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          color: SupabaseConfig.isConfigured
                              ? AppColors.worthItGreen
                              : AppColors.considerAmber,
                          size: 24,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SupabaseConfig.isConfigured
                                    ? "Supabase Terhubung"
                                    : "Supabase Mode Standby",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                SupabaseConfig.isConfigured
                                    ? "Proyek terhubung dengan PostgreSQL cloud."
                                    : "Isi URL & Anon Key di supabase_config.dart untuk mengaktifkan cloud.",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tentang Aplikasi
                  Text(
                    "Tentang Aplikasi",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              AppStrings.appName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            Spacer(),
                            Text("Versi 1.0.0",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.appTagline,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const Divider(height: 20),
                        const Text(
                          "Dikembangkan dengan Flutter & Supabase Cloud menggunakan Material Design 3 untuk membantu mahasiswa dan masyarakat membuat keputusan belanja yang lebih bijak, rasional, dan hemat.",
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Out Button (if logged in)
                  if (isLoggedIn)
                    CustomButton(
                      text: "Keluar dari Akun",
                      isSecondary: true,
                      icon: Icons.logout_rounded,
                      onPressed: _handleSignOut,
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
