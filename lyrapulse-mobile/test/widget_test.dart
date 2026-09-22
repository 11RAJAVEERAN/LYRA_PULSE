import 'package:flutter_test/flutter_test.dart';

import 'package:lyrapulse_mobile/app/app.dart';

void main() {
  testWidgets('Lyra Pulse navigates from splash to login', (tester) async {
    await tester.pumpWidget(const LyraPulseApp());
    expect(find.text('Employee Attendance'), findsOneWidget);
    expect(find.text('Tap your finger'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
