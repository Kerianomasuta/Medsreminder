import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meds_reminder/models/medicine.dart';
import 'package:meds_reminder/screens/patient/medicine_catalog_page.dart';

void main() {
  testWidgets('adds multiple medicine inputs without an image field', (
    tester,
  ) async {
    List<MedicineInput>? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDialog<List<MedicineInput>>(
                  context: context,
                  builder: (_) => const MedicineFormDialog(),
                );
              },
              child: const Text('Mở form'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();

    expect(find.textContaining('URL hình ảnh'), findsNothing);
    expect(find.text('1 thuốc'), findsOneWidget);

    await tester.tap(find.text('Thêm thuốc khác'));
    await tester.pumpAndSettle();

    expect(find.text('2 thuốc'), findsOneWidget);
    expect(find.text('Thuốc 2'), findsOneWidget);
    expect(find.text('Thêm 2 thuốc'), findsOneWidget);

    final nameFields = find.byType(TextFormField);
    await tester.enterText(nameFields.at(0), 'Paracetamol');
    await tester.ensureVisible(nameFields.at(3));
    await tester.enterText(nameFields.at(3), 'Vitamin C');
    await tester.tap(find.text('Thêm 2 thuốc'));
    await tester.pumpAndSettle();

    expect(result, hasLength(2));
    expect(result![0].name, 'Paracetamol');
    expect(result![1].name, 'Vitamin C');
  });
}
