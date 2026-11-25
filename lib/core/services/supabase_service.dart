import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/purchase_analysis.dart';
import '../models/price_comparison.dart';
import '../models/user_profile.dart';

class SupabaseService {
  static SupabaseClient? get client {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isInitialized => client != null;

  static User? get currentUser => client?.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // ================= AUTHENTICATION =================

  static Future<void> ensureProfileExists() async {
    final cli = client;
    final user = currentUser;
    if (cli == null || user == null) return;
    try {
      await cli.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ??
            (user.email != null ? user.email!.split('@').first : 'Sobat WorthIt'),
      });
    } catch (e) {
      print("Info ensureProfileExists: $e");
    }
  }

  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cli = client;
    if (cli == null) {
      throw Exception(
          "Supabase belum dikonfigurasi. Jalankan aplikasi dengan argumen --dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_ANON_KEY=...");
    }
    final res = await cli.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    if (res.user != null) {
      await ensureProfileExists();
    }
    return res;
  }

  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final cli = client;
    if (cli == null) {
      throw Exception(
          "Supabase belum dikonfigurasi. Jalankan aplikasi dengan argumen --dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_ANON_KEY=...");
    }
    final res = await cli.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user != null) {
      await ensureProfileExists();
    }
    return res;
  }

  static Future<void> signOut() async {
    final cli = client;
    if (cli != null) {
      await cli.auth.signOut();
    }
  }

  static Future<UserProfile?> fetchUserProfile() async {
    final cli = client;
    final user = currentUser;
    if (cli == null || user == null) return null;

    try {
      final res =
          await cli.from('profiles').select().eq('id', user.id).maybeSingle();
      if (res != null) {
        return UserProfile.fromMap(res);
      }
      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? 'Sobat WorthIt',
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? 'Sobat WorthIt',
        createdAt: DateTime.now(),
      );
    }
  }

  // ================= PURCHASE ANALYSES (CRUD) =================

  static Future<void> savePurchaseAnalysis(PurchaseAnalysis analysis) async {
    final cli = client;
    final user = currentUser;
    if (cli == null || user == null) return;

    await ensureProfileExists();

    final map = analysis.toMap();
    map['user_id'] = user.id;

    await cli.from('purchase_analyses').insert(map);
  }

  static Future<List<PurchaseAnalysis>> fetchPurchaseAnalyses() async {
    final cli = client;
    final user = currentUser;
    if (cli == null || user == null) return [];

    try {
      final res = await cli
          .from('purchase_analyses')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (res as List)
          .map((item) => PurchaseAnalysis.fromMap(item))
          .toList();
    } catch (e) {
      print("Error fetching purchase analyses from Supabase: $e");
      return [];
    }
  }

  static Future<void> deletePurchaseAnalysis(String id) async {
    final cli = client;
    final user = currentUser;
    if (cli == null || user == null) return;

    await cli
        .from('purchase_analyses')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  // ================= PRICE COMPARISONS (CRUD) =================

  static Future<void> savePriceComparison(PriceComparison comp) async {
    final cli = client;
    final user = currentUser;
    if (cli == null || user == null) return;

    await ensureProfileExists();

    final map = comp.toMap();
    map['user_id'] = user.id;

    await cli.from('price_comparisons').insert(map);
  }

  static Future<List<PriceComparison>> fetchPriceComparisons() async {
    final cli = client;
    final user = currentUser;
    if (cli == null || user == null) return [];

    try {
      final res = await cli
          .from('price_comparisons')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (res as List)
          .map((item) => PriceComparison.fromMap(item))
          .toList();
    } catch (e) {
      print("Error fetching price comparisons from Supabase: $e");
      return [];
    }
  }

  static Future<void> deletePriceComparison(String id) async {
    final cli = client;
    final user = currentUser;
    if (cli == null || user == null) return;

    await cli
        .from('price_comparisons')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  // ================= SYNC GUEST DATA TO CLOUD =================

  static Future<int> syncGuestDataToCloud({
    required List<PurchaseAnalysis> localAnalyses,
    required List<PriceComparison> localComparisons,
  }) async {
    final cli = client;
    final user = currentUser;
    if (cli == null || user == null) return 0;

    await ensureProfileExists();

    int totalSynced = 0;

    // Sync Analyses
    for (var a in localAnalyses) {
      try {
        final map = a.toMap();
        map['user_id'] = user.id;
        await cli.from('purchase_analyses').upsert(map);
        totalSynced++;
      } catch (e) {
        print("Error syncing analysis ${a.id}: $e");
      }
    }

    // Sync Comparisons
    for (var c in localComparisons) {
      try {
        final map = c.toMap();
        map['user_id'] = user.id;
        await cli.from('price_comparisons').upsert(map);
        totalSynced++;
      } catch (e) {
        print("Error syncing comparison ${c.id}: $e");
      }
    }

    return totalSynced;
  }
}
