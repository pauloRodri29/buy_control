import 'package:buy_control/app/theme/app_theme.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_dropdown.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/filter_chips_bar.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/app/widgets/search_field_debounced.dart';
import 'package:buy_control/app/widgets/selectable_list_tile.dart';
import 'package:buy_control/app/widgets/text_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(ThemeMode mode, Widget body) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: mode,
    scaffoldMessengerKey: appScaffoldMessengerKey,
    home: Scaffold(body: body),
  );
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('widgets compartilhados renderizam no tema ${mode.name}', (tester) async {
      String? chip;
      await tester.pumpWidget(_app(
        mode,
        StatefulBuilder(
          builder: (context, setState) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppText.title('Título'),
              const AppText('Corpo'),
              const AppText.subtitle('Subtítulo'),
              const AppButton(label: 'Primário', onPressed: null),
              AppButton.secondary(label: 'Secundário', onPressed: () {}),
              AppButton.danger(label: 'Perigo', icon: Icons.delete, onPressed: () {}),
              AppButton.text(label: 'Texto', onPressed: () {}),
              AppCard(onTap: () {}, child: const Text('Card')),
              const AppTextField(label: 'Nome', hint: 'Digite', errorText: 'Obrigatório'),
              AppDropdown<String>(
                label: 'Opção',
                value: 'a',
                options: const [AppDropdownOption(value: 'a', label: 'A')],
                onChanged: (_) {},
              ),
              SearchFieldDebounced(onChanged: (_) {}),
              FilterChipsBar(
                options: const [FilterChipOption(key: 'x', label: 'X'), FilterChipOption(key: 'y', label: 'Y')],
                selectedKey: chip,
                onSelected: (k) => setState(() => chip = k),
              ),
              SelectableListTile(title: 'Item', subtitle: 'detalhe', trailingText: '3', selected: true, onTap: () {}),
              const LoadingSkeleton(height: 20),
              const SizedBox(height: 200, child: EmptyStateView(title: 'Vazio', message: 'Nada aqui')),
              SizedBox(height: 200, child: ErrorStateView(message: 'Erro', onRetry: () {})),
            ],
          ),
        ),
      ));

      await tester.tap(find.text('X'));
      await tester.pump();
      expect(chip, 'x');

      AppFeedback.success('Salvo!', title: 'Pronto');
      await tester.pump();
      expect(find.text('Salvo!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('diálogos e bottom sheet nativos abrem no tema ${mode.name}', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(mode, Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      })));

      final confirm = ConfirmDialog.show(ctx, title: 'Excluir?', message: 'Sem volta.');
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      expect(await confirm, isTrue);

      final input = TextInputDialog.show(ctx, title: 'Nome');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  Café  ');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await input, 'Café');

      AppBottomSheet.show<void>(ctx, child: const Text('Conteúdo do sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Conteúdo do sheet'), findsOneWidget);
    });
  }
}
