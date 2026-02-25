// Basic widget test for TOS Driver App
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tos_driver_app/app.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: TosDriverApp(),
      ),
    );

    // Verify that the app displays the setup complete message
    expect(find.text('TOS Driver App - Setup Complete'), findsOneWidget);
  });
}
