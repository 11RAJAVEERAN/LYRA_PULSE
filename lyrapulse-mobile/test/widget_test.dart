import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lyrapulse_mobile/app/app.dart';

void main() {
  testWidgets('Lyra Pulse splash navigates to employee login', (tester) async {
    const secureStorageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (call) async => null,
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null));

    await tester.pumpWidget(const LyraPulseApp());
    expect(find.text('Lyra Pulse'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Employee Login'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}
