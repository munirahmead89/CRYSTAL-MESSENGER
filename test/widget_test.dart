import 'package:flutter_test/flutter_test.dart';
import 'package:crystal_messenger/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CrystalMessengerApp());
  });
}

