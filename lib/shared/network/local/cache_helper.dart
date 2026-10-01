

import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static SharedPreferences? sharedPreferences;

  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  // ─── Boolean ─────────────────────────────────
  static Future<bool> putBoolean({
    required String key,
    required bool value,
  }) async {
    return await sharedPreferences!.setBool(key, value);
  }

  // ─── Generic Save ────────────────────────────
  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (value is String) return await sharedPreferences!.setString(key, value);
    if (value is int) return await sharedPreferences!.setInt(key, value);
    if (value is bool) return await sharedPreferences!.setBool(key, value);
    if (value is double) return await sharedPreferences!.setDouble(key, value);
    if (value is List<String>) {
      return await sharedPreferences!.setStringList(key, value);
    }
    return await sharedPreferences!.setString(key, value.toString());
  }

  // ─── Generic Get ─────────────────────────────
  static dynamic getData({required String key}) {
    return sharedPreferences!.get(key);
  }

  static String? getString({required String key}) {
    return sharedPreferences!.getString(key);
  }

  static int? getInt({required String key}) {
    return sharedPreferences!.getInt(key);
  }

  static bool? getBool({required String key}) {
    return sharedPreferences!.getBool(key);
  }

  // ─── Remove ──────────────────────────────────
  static Future<bool> removeData({required String key}) async {
    return await sharedPreferences!.remove(key);
  }

  // ─── Clear All ───────────────────────────────
  static Future<bool> clear() async {
    return await sharedPreferences!.clear();
  }

  // ─── Chatwoot Specific Keys ──────────────────
  static const String keyContactId = 'contact_identifier';
  static const String keyContactToken = 'contact_pubsub_token';
  static const String keyConversationId = 'conversation_id';
  static const String keySourceId = 'contact_source_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyInboxId = 'inbox_identifier';
  static const String keyIsDark = 'is_dark_mode';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyAuthToken = 'auth_token';
  static const String keyAccountId = 'account_id';
  static const String keyUserId = 'user_id';
  static const String keyLynomiaToken = 'lynomia_token';
  static const String keyClient = 'auth_client';
  static const String keyUid = 'auth_uid';

  // ─── Remove Helper ───────────────────────────
  static Future<bool> remove({required String key}) async {
    return await sharedPreferences!.remove(key);
  }
}