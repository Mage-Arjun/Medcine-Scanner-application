import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/app.dart';
import 'package:medcam_app/providers/tab_provider.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MedCamApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('MediCam'), findsOneWidget);
  });

  testWidgets('Bottom nav renders all 3 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MedCamApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('Tab navigation switches active tab', (WidgetTester tester) async {
    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MedCamApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(tabProvider), equals(0));

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(container.read(tabProvider), equals(1));

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(container.read(tabProvider), equals(2));

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(container.read(tabProvider), equals(0));

    container.dispose();
  });
}
