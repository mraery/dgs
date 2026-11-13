import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dgs_quest/screens/main_navigation_screen.dart';

void main() {
  testWidgets('DGS Quest smoke test - renders units and stats', (WidgetTester tester) async {
    await tester.pumpWidget(
      // Uygulama artık WelcomeScreen ile açılıyor (sonsuz animasyonlu);
      // ana ekranı doğrudan test ediyoruz.
      const ProviderScope(
        child: MaterialApp(home: MainNavigationScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify stats and title render
    expect(find.text('Temel Kavramlar & Sayı Kümeleri'), findsOneWidget);
  });
}
