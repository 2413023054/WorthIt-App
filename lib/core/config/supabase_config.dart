class SupabaseConfig {
  /// Membaca Project URL dan Anon/Publishable Key dari lingkungan `--dart-define`.
  /// Kredensial tidak di-hardcode ke dalam kode sumber demi keamanan.
  ///
  /// Contoh penggunaan saat menjalankan atau membangun aplikasi:
  /// flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
  ///
  /// Mendukung key:
  /// - SUPABASE_URL
  /// - SUPABASE_ANON_KEY atau SUPABASE_PUBLISHABLE_KEY

  static const String _rawUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _rawKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: '',
    ),
  );

  /// URL Proyek Supabase yang sudah dibersihkan dari spasi dan trailing slash
  static String get url {
    final trimmed = _rawUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Anon / Publishable Key Supabase
  static String get anonKey => _rawKey.trim();

  /// Status apakah kredensial telah diberikan
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
