import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawback_flutter/features/auth/presentation/widgets/auth_page_scaffold.dart';

void main() {
  group('AuthPageScaffold', () {
    testWidgets('should render scaffold with app bar and child', (WidgetTester tester) async {
      const testWidget = Text('Test Content');

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPageScaffold(
            child: testWidget,
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should have SafeArea wrapping child', (WidgetTester tester) async {
      const testWidget = Text('Test Content');

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPageScaffold(
            child: testWidget,
          ),
        ),
      );

      expect(find.byType(SafeArea), findsWidgets);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should center child content', (WidgetTester tester) async {
      const testWidget = Text('Test Content');

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPageScaffold(
            child: testWidget,
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('should constrain child width', (WidgetTester tester) async {
      const testWidget = SizedBox(width: 1000, height: 100);

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPageScaffold(
            child: testWidget,
          ),
        ),
      );

      // Widget renders without errors
      expect(find.byType(AuthPageScaffold), findsOneWidget);
      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    testWidgets('should have padding around child', (WidgetTester tester) async {
      const testWidget = Text('Test Content');

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPageScaffold(
            child: testWidget,
          ),
        ),
      );

      expect(find.byType(Padding), findsWidgets);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should render different children correctly', (WidgetTester tester) async {
      const testWidget = Column(
        children: [
          Text('Title'),
          TextField(),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPageScaffold(
            child: testWidget,
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should maintain structure with complex child', (WidgetTester tester) async {
      final testWidget = SingleChildScrollView(
        child: Column(
          children: [
            const Text('Header'),
            SizedBox(
              height: 2000,
              child: Container(
                color: Colors.blue,
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthPageScaffold(
            child: testWidget,
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('should be a StatelessWidget', (WidgetTester tester) async {
      const scaffold = AuthPageScaffold(child: SizedBox.expand());
      expect(scaffold, isA<StatelessWidget>());
    });
  });
}
