import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_strings.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/screens/main_navigation_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inisialisasi Penyimpanan Lokal (SharedPreferences)
  final localStorage = await LocalStorageService.init();

  // Inisialisasi Supabase secara aman jika kredensial sudah diatur
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
    } catch (e) {
      debugPrint("Koneksi Supabase standby / offline: $e");
    }
  }

  // Tentukan mode tema awal dari preferensi lokal
  final savedTheme = localStorage.getThemeMode();
  ThemeMode initialThemeMode = ThemeMode.system;
  if (savedTheme == 'light') {
    initialThemeMode = ThemeMode.light;
  } else if (savedTheme == 'dark') {
    initialThemeMode = ThemeMode.dark;
  }

  runApp(WorthItApp(
    localStorage: localStorage,
    initialThemeMode: initialThemeMode,
  ));
}

class WorthItApp extends StatefulWidget {
  final LocalStorageService localStorage;
  final ThemeMode initialThemeMode;

  const WorthItApp({
    super.key,
    required this.localStorage,
    required this.initialThemeMode,
  });

  @override
  State<WorthItApp> createState() => _WorthItAppState();
}

class _WorthItAppState extends State<WorthItApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void _updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSeenOnboarding = widget.localStorage.hasSeenOnboarding();

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: hasSeenOnboarding
          ? MainNavigationScreen(
              localStorage: widget.localStorage,
              onThemeModeChanged: _updateThemeMode,
            )
          : OnboardingScreen(
              localStorage: widget.localStorage,
            ),
    );
  }
}
