import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/purchase_analysis.dart';
import '../models/price_comparison.dart';

class LocalStorageService {
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String _keyGuestAnalyses = 'guest_purchase_analyses';
  static const String _keyGuestComparisons = 'guest_price_comparisons';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Onboarding
  bool hasSeenOnboarding() {
    return _prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_keyHasSeenOnboarding, value);
  }

  // Theme (light, dark, system)
  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  // Guest Analyses
  List<PurchaseAnalysis> getGuestAnalyses() {
    final raw = _prefs.getStringList(_keyGuestAnalyses) ?? [];
    return raw
        .map((item) => PurchaseAnalysis.fromJson(item))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveGuestAnalysis(PurchaseAnalysis analysis) async {
    final list = getGuestAnalyses();
    list.insert(0, analysis);
    final rawList = list.map((item) => item.toJson()).toList();
    await _prefs.setStringList(_keyGuestAnalyses, rawList);
  }

  Future<void> deleteGuestAnalysis(String id) async {
    final list = getGuestAnalyses();
    list.removeWhere((item) => item.id == id);
    final rawList = list.map((item) => item.toJson()).toList();
    await _prefs.setStringList(_keyGuestAnalyses, rawList);
  }

  // Guest Price Comparisons
  List<PriceComparison> getGuestComparisons() {
    final raw = _prefs.getStringList(_keyGuestComparisons) ?? [];
    return raw
        .map((item) => PriceComparison.fromJson(item))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveGuestComparison(PriceComparison comp) async {
    final list = getGuestComparisons();
    list.insert(0, comp);
    final rawList = list.map((item) => item.toJson()).toList();
    await _prefs.setStringList(_keyGuestComparisons, rawList);
  }

  Future<void> deleteGuestComparison(String id) async {
    final list = getGuestComparisons();
    list.removeWhere((item) => item.id == id);
    final rawList = list.map((item) => item.toJson()).toList();
    await _prefs.setStringList(_keyGuestComparisons, rawList);
  }

  // Clear all guest data after syncing to cloud
  Future<void> clearGuestData() async {
    await _prefs.remove(_keyGuestAnalyses);
    await _prefs.remove(_keyGuestComparisons);
  }
}
