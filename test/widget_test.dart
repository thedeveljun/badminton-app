import 'package:flutter_test/flutter_test.dart';

import 'package:funminton_club_app/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FunmintonApp());
  });
}
