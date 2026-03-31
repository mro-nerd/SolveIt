import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY not found in .env file');
    }

    // TODO: replace with proper Supabase Auth sync before production.
    // For hackathon: use service_role key to bypass RLS entirely.
    // This is safe only because we control the app and data.
    final serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
    final effectiveKey = serviceRoleKey ?? anonKey;

    if (serviceRoleKey != null) {
      debugPrint('[Supabase] Initializing with service_role key (RLS bypassed)');
    } else {
      debugPrint('[Supabase] WARNING: No service_role key found, using anon key — RLS may block writes');
    }

    await Supabase.initialize(
      url: url,
      anonKey: effectiveKey,
    );
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
