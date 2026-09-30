import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lyrapulse_mobile/app/app.dart';

void main() {
  testWidgets('Lyra Pulse navigates from splash to login', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LyraPulseApp());
    expect(find.text('Lyra Pulse'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
