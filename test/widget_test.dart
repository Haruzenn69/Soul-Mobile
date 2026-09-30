import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soul/main.dart';

void main() {
  testWidgets('app boots and shows splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SoulApp()));
    await tester.pump();
    expect(find.text('SOUL'), findsOneWidget);
  });
}