import 'package:buy_control/app/errors/app_error_handler.dart';
import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/theme/app_theme.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget body) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    scaffoldMessengerKey: appScaffoldMessengerKey,
    home: Scaffold(body: body),
  );
}

void main() {
  group('FailurePresenter.show', () {
    testWidgets('mostra a mensagem da falha com título padrão por tipo', (tester) async {
      await tester.pumpWidget(_app(const SizedBox()));

      FailurePresenter.show(const CacheFailure());
      await tester.pump();
      expect(find.text('Não foi possível concluir'), findsOneWidget);
      expect(find.text('Falha ao acessar os dados locais.'), findsOneWidget);

      FailurePresenter.show(const ValidationFailure('Nome obrigatório.'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Confira os dados'), findsOneWidget);
      expect(find.text('Nome obrigatório.'), findsOneWidget);

      FailurePresenter.show(const NotImplementedFailure());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Em breve'), findsOneWidget);
    });

    testWidgets('título explícito substitui o padrão', (tester) async {
      await tester.pumpWidget(_app(const SizedBox()));
      FailurePresenter.show(const UnknownFailure(), title: 'Erro ao exportar');
      await tester.pump();
      expect(find.text('Erro ao exportar'), findsOneWidget);
    });

    testWidgets('showIfFailure só avisa quando o resultado é falha', (tester) async {
      await tester.pumpWidget(_app(const SizedBox()));

      expect(FailurePresenter.showIfFailure(const Success<void>(null)), isTrue);
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);

      expect(FailurePresenter.showIfFailure(const Failure<void>(NotFoundFailure())), isFalse);
      await tester.pump();
      expect(find.text('Registro não encontrado.'), findsOneWidget);
    });
  });

  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    testWidgets('AppErrorWidget renderiza no tema ${theme.brightness.name}', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: theme, home: const AppErrorWidget()));
      expect(find.text('Não foi possível mostrar este conteúdo.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
