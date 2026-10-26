import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DioFlow Demo UI smoke test and mock request verification', (
    WidgetTester tester,
  ) async {
    await setupDioFlow();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify main components are rendered
    expect(find.text('DioFlow Demo'), findsOneWidget);
    expect(find.text('Mock Mode'), findsOneWidget);
    expect(find.byKey(const Key('get-user-button')), findsOneWidget);
    expect(find.byKey(const Key('post-user-button')), findsOneWidget);
    expect(find.byKey(const Key('cached-feed-button')), findsOneWidget);
    expect(find.byKey(const Key('upload-file-button')), findsOneWidget);

    // Tap GET User button
    await tester.tap(find.byKey(const Key('get-user-button')));
    await tester.pumpAndSettle();

    // Verify mock response data appears in response inspector
    expect(find.textContaining('Sarah Connor'), findsOneWidget);
    expect(find.textContaining('Status 200'), findsOneWidget);

    // Tap POST User button
    await tester.tap(find.byKey(const Key('post-user-button')));
    await tester.pumpAndSettle();

    // Verify post response appears
    expect(find.textContaining('John Doe'), findsOneWidget);
    expect(find.textContaining('Status 201'), findsOneWidget);

    // Tap Upload button
    await tester.tap(find.byKey(const Key('upload-file-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('upl_2026'), findsOneWidget);
  });
}
