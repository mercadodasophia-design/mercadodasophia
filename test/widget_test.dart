// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mercadodasophia/main.dart';

void main() {
  testWidgets('Mercado da Sophia smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MercadoDaSophiaApp());

    // Verify that our app shows the main screen
    expect(find.text('Mercado da Sophia'), findsOneWidget);
    expect(find.text('Bem-vindo ao Mercado da Sophia'), findsOneWidget);
    expect(find.text('Produtos selecionados com carinho'), findsOneWidget);
  });
}
