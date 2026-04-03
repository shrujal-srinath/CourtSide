// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:courtside/app.dart';
import 'package:courtside/screens/splash/splash_screen.dart';

void main() {
  testWidgets('App launches splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CourtsideApp());

    // Verify that the splash screen appears.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Verify splash screen is visible before the end of the animation timer.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
