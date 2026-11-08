import 'package:buy_control/app/widgets/app_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> _pumpLauncher(WidgetTester tester, Future<Object?> Function(BuildContext) open, List<Object?> results) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async => results.add(await open(context)),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ));
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('data única: atalho e dia tocado são retornados ao confirmar', (tester) async {
    final results = <Object?>[];
    await _pumpLauncher(
      tester,
      (context) => AppDatePicker.show(
        context,
        title: 'Data de previsão',
        initialDate: DateTime(2026, 11, 10),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        shortcuts: [AppDateShortcut('Natal', DateTime(2026, 12, 25))],
      ),
      results,
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Novembro 2026'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    // Data local, sem horário (não UTC).
    expect(results.single, DateTime(2026, 11, 15));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Natal'));
    await tester.pumpAndSettle();
    expect(find.text('Dezembro 2026'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(results.last, DateTime(2026, 12, 25));
  });

  testWidgets('intervalo: dois toques definem início e fim', (tester) async {
    final results = <Object?>[];
    await _pumpLauncher(
      tester,
      (context) => AppDatePicker.showRange(
        context,
        title: 'Período',
        initialRange: DateTimeRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 2)),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      ),
      results,
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    final range = results.single as DateTimeRange;
    expect(range.start, DateTime(2026, 11, 5));
    expect(range.end, DateTime(2026, 11, 12));
  });
}
