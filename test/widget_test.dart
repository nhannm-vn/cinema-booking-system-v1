import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/shared/widgets/app_badge.dart';
import 'package:cinema_booking_v1/shared/widgets/spec_cell.dart';

void main() {
  testWidgets('AppBadge and SpecCell render test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppBadge(label: 'IMAX'),
              SpecCell(value: '128', label: 'PHÚT'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('IMAX'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('PHÚT'), findsOneWidget);
  });
}
