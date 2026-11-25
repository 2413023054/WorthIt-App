import 'package:flutter/material.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../navigation/screens/main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final LocalStorageService localStorage;

  const LoginScreen({super.key, required this.localStorage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!SupabaseConfig.isConfigured) {
      _showSupabaseNotConfiguredDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res?.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil masuk! Selamat datang kembali."),
            backgroundColor: AppColors.worthItGreen,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                MainNavigationScreen(localStorage: widget.localStorage),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal masuk: ${e.toString()}"),
            backgroundColor: AppColors.notWorthItRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSupabaseNotConfiguredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Koneksi Supabase Belum Diatur"),
        content: const Text(
          "Project URL dan Anon Key Supabase masih menggunakan placeholder di file lib/core/config/supabase_config.dart.\n\nAnda dapat melanjutkan eksplorasi menggunakan Mode Tamu tanpa batasan fitur!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      MainNavigationScreen(localStorage: widget.localStorage),
                ),
                (route) => false,
              );
            },
            child: const Text("Lanjut Mode Tamu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Masuk Akun"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat Datang Kembali 👋",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Masuk untuk menyinkronkan data riwayat analisis belanja ke database cloud Supabase.",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  controller: _emailController,
                  label: "Alamat Email",
                  hint: "contoh@email.com",
                  prefixIcon: Icons.email_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Email tidak boleh kosong";
                    }
                    if (!val.contains('@')) {
                      return "Format email tidak valid";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                CustomTextField(
                  controller: _passwordController,
                  label: "Kata Sandi",
                  hint: "Minimal 6 karakter",
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Kata sandi tidak boleh kosong";
                    }
                    if (val.length < 6) {
                      return "Kata sandi minimal 6 karakter";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: "Masuk Sekarang",
                  icon: Icons.login_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum memiliki akun? ",
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(
                                localStorage: widget.localStorage),
                          ),
                        );
                      },
                      child: Text(
                        "Daftar Sekarang",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.secondaryCyan
                              : AppColors.primaryIndigo,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
