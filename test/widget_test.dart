// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// Gene - Nov, 03, 2026: Updated smoke test to verify BookIt app launches with discovery header
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/main.dart';

void main() {
  testWidgets('BookIt launches and displays header brand', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BookItApp()));
    await tester.pumpAndSettle();

    expect(find.text('BookIt'), findsOneWidget);
    expect(find.text('Find clinics, doctors & services'), findsOneWidget);
  });
}

/*
// Gene - Nov, 03, 2026: Preserved initial counter smoke test
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
*/

