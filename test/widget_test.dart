// Smoke test: the app boots and shows the splash screen.
//
// CourtsideApp is a ConsumerWidget that watches routerProvider, so it must be
// wrapped in a ProviderScope. The router redirect reads auth state, which needs
// dotenv + Supabase initialized — mirror main()'s bootstrap with dummy values.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:courtside/app.dart';
import 'package:courtside/screens/splash/splash_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(mergeWith: {
      'SUPABASE_URL': 'http://localhost',
      'SUPABASE_ANON_KEY': 'test-anon-key',
      'RAZORPAY_KEY_ID': 'test',
    });
    await Supabase.initialize(
      url: 'http://localhost',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('App launches splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CourtsideApp()));

    // Splash is the first route.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Still visible before the animation timer completes.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
