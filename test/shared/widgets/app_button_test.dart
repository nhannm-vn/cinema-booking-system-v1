import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/shared/widgets/app_button.dart';

void main() {
  group('AppButton Tests', () {
    testWidgets('renders uppercase label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              label: 'Đặt vé ngay',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('ĐẶT VÉ NGAY'), findsOneWidget);
    });

    testWidgets('triggers onPressed when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              label: 'TIẾP TỤC',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('TIẾP TỤC'));
      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              label: 'TIẾP TỤC',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('TIẾP TỤC'), findsNothing);
    });
  });
}
