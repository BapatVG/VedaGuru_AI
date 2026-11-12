import 'package:flutter_test/flutter_test.dart';
import 'package:vedaguru_mobile/main.dart';

void main() {
  testWidgets('VedaGuru smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VedaGuruApp());
    expect(find.text('VedaGuru AI'), findsWidgets);
  });
}
