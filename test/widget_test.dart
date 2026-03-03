import 'package:flutter_test/flutter_test.dart';
import 'package:arbitrex/main.dart';
import 'package:provider/provider.dart';
import 'package:arbitrex/providers/feed_provider.dart';
import 'package:arbitrex/providers/user_provider.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FeedProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const PolyfoxApp(),
      ),
    );

    // Verify that the login screen is shown.
    expect(find.text('Prediction markets intelligence'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
