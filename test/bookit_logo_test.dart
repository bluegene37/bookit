// Gene - Nov, 08, 2026: Widget and CustomPainter unit tests for the minimalist Geometric 'B' + Checkmark BookItLogo
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/core/theme/neumorphic_colors.dart';
import 'package:bookit/core/theme/neumorphic_theme.dart';
import 'package:bookit/core/widgets/bookit_logo.dart';
import 'package:bookit/core/widgets/neumorphic_container.dart';

void main() {
  group('BookItLogo Widget & Painter Tests', () {
    testWidgets('renders BookItLogo with Neumorphic badge by default at specified size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NeumorphicTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: BookItLogo(size: 72),
            ),
          ),
        ),
      );

      expect(find.byType(BookItLogo), findsOneWidget);
      expect(find.byType(NeumorphicContainer), findsOneWidget);
      /*
      // Gene - Nov, 08, 2026: Generic find.byType(CustomPaint) matched both container decoration and BookItLogoPainter
      expect(
        find.descendant(
          of: find.byType(BookItLogo),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      */
      // Gene - Nov, 08, 2026: Specifically assert that CustomPaint with BookItLogoPainter is rendered inside BookItLogo
      expect(
        find.descendant(
          of: find.byType(BookItLogo),
          matching: find.byWidgetPredicate(
            (widget) => widget is CustomPaint && widget.painter is BookItLogoPainter,
          ),
        ),
        findsOneWidget,
      );

      final containerSize = tester.getSize(find.byType(BookItLogo));
      expect(containerSize.width, 72);
      expect(containerSize.height, 72);
    });

    testWidgets('renders standalone mark without NeumorphicContainer when showBadge is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NeumorphicTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: BookItLogo(size: 48, showBadge: false),
            ),
          ),
        ),
      );

      expect(find.byType(BookItLogo), findsOneWidget);
      expect(find.byType(NeumorphicContainer), findsNothing);
      expect(
        find.descendant(
          of: find.byType(BookItLogo),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders wordmark when showWordmark is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NeumorphicTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: BookItLogo(size: 44, showWordmark: true),
            ),
          ),
        ),
      );

      expect(find.text('BookIt'), findsOneWidget);
    });

    test('BookItLogoPainter shouldRepaint returns true when colors or brightness change', () {
      const painterLight = BookItLogoPainter(
        primaryColor: NeumorphicColors.tealPrimary,
        accentColor: NeumorphicColors.cyanAccent,
        isDark: false,
      );
      const painterLightSame = BookItLogoPainter(
        primaryColor: NeumorphicColors.tealPrimary,
        accentColor: NeumorphicColors.cyanAccent,
        isDark: false,
      );
      const painterDark = BookItLogoPainter(
        primaryColor: NeumorphicColors.tealLight,
        accentColor: NeumorphicColors.cyanLight,
        isDark: true,
      );

      expect(painterLight.shouldRepaint(painterLightSame), isFalse);
      expect(painterLight.shouldRepaint(painterDark), isTrue);
    });
  });
}
