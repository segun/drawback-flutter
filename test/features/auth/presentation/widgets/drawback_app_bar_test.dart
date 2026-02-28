import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawback_flutter/features/auth/presentation/widgets/drawback_app_bar.dart';

void main() {
  group('DrawbackAppBar', () {
    testWidgets('should render AppBar with correct appearance', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const DrawbackAppBar(),
            body: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(DrawbackAppBar), findsOneWidget);
    });

    testWidgets('should have correct preferred size', (WidgetTester tester) async {
      const appBar = DrawbackAppBar();
      expect(appBar.preferredSize.height, kToolbarHeight);
    });

    testWidgets('should display logo image', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const DrawbackAppBar(),
            body: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should have rose-200 background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const DrawbackAppBar(),
            body: const SizedBox.expand(),
          ),
        ),
      );

      final appBarFinder = find.byType(AppBar);
      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.backgroundColor, const Color.fromARGB(255, 245, 184, 202));
    });

    testWidgets('should have zero elevation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const DrawbackAppBar(),
            body: const SizedBox.expand(),
          ),
        ),
      );

      final appBarFinder = find.byType(AppBar);
      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.elevation, 0);
    });

    testWidgets('should center the title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const DrawbackAppBar(),
            body: const SizedBox.expand(),
          ),
        ),
      );

      final appBarFinder = find.byType(AppBar);
      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.centerTitle, true);
    });

    testWidgets('should have rose-800 foreground color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const DrawbackAppBar(),
            body: const SizedBox.expand(),
          ),
        ),
      );

      final appBarFinder = find.byType(AppBar);
      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.foregroundColor, const Color(0xFF9F1239));
    });
  });
}
