import 'package:flutter_test/flutter_test.dart';
import 'package:ace_mobile/backend/backend.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Configuration Tests', () {
    test('Environment variables can be loaded', () async {
      await dotenv.load(fileName: '.env');

      expect(dotenv.env['SUPABASE_URL'], isNotNull);
      expect(dotenv.env['SUPABASE_ANON_KEY'], isNotNull);
    });

    test('SupabaseClientManager initialization logic handles env vars', () async {
       await dotenv.load(fileName: '.env');
      
      expect(() => SupabaseClientManager.initialize(), returnsNormally);
    });
  });
}
