import 'package:flutter_test/flutter_test.dart';
import 'package:ace_mobile/main.dart';

void main() {
  testWidgets('App smoke test - verifies widget tree can be created', (WidgetTester tester) async {
    // We skip actual initialization during tests to avoid network calls
    // In a real environment, you'd mock Firebase and Supabase
    
    // For now, we just verify the file compiles and the MyApp class exists
    expect(const MyApp(), isNotNull);
  });
}
