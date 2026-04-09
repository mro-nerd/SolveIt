import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    final url = dotenv.env['SUPABASE_URL']!;
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;
    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
    debugPrint('[Supabase] Initialized with anon key. RLS is active.');
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => Supabase.instance.client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
}
