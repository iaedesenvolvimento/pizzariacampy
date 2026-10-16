import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pizzaria_mobile/features/admin/components/admin_scaffold.dart';
import 'package:pizzaria_mobile/features/admin/core/admin_navigation.dart';

void main() {
  testWidgets('renderiza shell administrativo e navegação principal', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const AdminScaffold(
          title: 'Painel administrativo',
          activeDestination: AdminDestinationId.dashboard,
          body: Text('Conteúdo do painel'),
        ),
      ),
    );

    expect(find.text('Painel administrativo'), findsOneWidget);
    expect(find.text('Conteúdo do painel'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
    expect(find.text('Cardápio'), findsOneWidget);
  });
}
