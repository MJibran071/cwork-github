import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/screens/escrow_screen.dart';

void main() {
  testWidgets('EscrowScreen should render correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: EscrowScreen(),
    ));

    // Verify that the screen title is displayed.
    expect(find.text('Escrow Screen'), findsOneWidget);
    
    // Verify the text style is as expected.
    final textWidget = tester.widget<Text>(find.text('Escrow Screen'));
    expect(textWidget.style?.fontSize, 24);
    expect(textWidget.style?.fontWeight, FontWeight.bold);
    
    // Verify the widget is centered.
    final centerWidget = tester.widget<Center>(find.byType(Center));
    expect(centerWidget, isNotNull);
  });
}