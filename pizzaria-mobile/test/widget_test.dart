import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pizzaria_mobile/features/auth/presentation/auth_pages.dart';

void main() {
  testWidgets('renders the authentication shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScaffold(
          title: 'Entrar',
          subtitle: 'Acesse sua conta.',
          child: Text('Formulário'),
        ),
      ),
    );

    expect(find.text('Entrar'), findsOneWidget);
  });
}
