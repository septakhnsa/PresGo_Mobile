// This is a basic Flutter widget test for PresGoApp.
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_presensi/main.dart';

void main() {
  testWidgets('PresGo App compilation and splash screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PresGoApp());

    // Verify that the splash screen or app name text 'PresGo' renders.
    expect(find.text('PresGo'), findsOneWidget);
  });
}
