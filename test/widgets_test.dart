import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financas_pbl_ap2b/main.dart';
import 'package:financas_pbl_ap2b/controllers/finance_controller.dart';
import 'package:financas_pbl_ap2b/repositories/finance_repository.dart';
import 'helpers/fakes.dart';

void main() {
  late FakeStore local;
  late FakeRemote remote;
  late FinanceController controller;
  setUp(() async {
    local = FakeStore();
    remote = FakeRemote();
    controller =
        FinanceController(FinanceRepository(local: local, remote: remote));
    await controller.carregar();
  });

  Future<void> open(WidgetTester tester, String route,
      {Object? arguments}) async {
    await tester.pumpWidget(FinanceApp(controller: controller));
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(route, arguments: arguments);
    await tester.pumpAndSettle();
  }

  testWidgets('01 - dashboard exibe saldo e receitas', (tester) async {
    await tester.pumpWidget(FinanceApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Saldo atual'), findsOneWidget);
    expect(find.text('Receitas'), findsOneWidget);
  });

  testWidgets('02 - listagem exibe mensagem vazia', (tester) async {
    await open(tester, '/lancamentos');
    expect(find.textContaining('Nenhum lançamento.'), findsOneWidget);
  });

  testWidgets('03 - formulário valida descrição obrigatória', (tester) async {
    await open(tester, '/novo');
    await tester.enterText(find.byType(TextFormField).at(1), '20,00');
    await tester.tap(find.text('Salvar lançamento'));
    await tester.pump();
    expect(find.text('Descrição obrigatória'), findsOneWidget);
  });

  testWidgets('04 - formulário valida valor positivo', (tester) async {
    await open(tester, '/novo');
    await tester.enterText(find.byType(TextFormField).first, 'Pagamento');
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.text('Salvar lançamento'));
    await tester.pump();
    expect(find.text('Informe um valor positivo'), findsOneWidget);
  });

  testWidgets('05 - tela de sincronização exibe pendências', (tester) async {
    await controller.salvarLancamento(lancamento());
    await open(tester, '/sincronizacao');
    expect(find.text('1 aguardando envio'), findsOneWidget);
    expect(find.text('Sincronizar agora'), findsOneWidget);
  });

  testWidgets('06 - lista exibe item salvo e estado de nuvem', (tester) async {
    await controller.salvarLancamento(lancamento());
    await open(tester, '/lancamentos');
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsWidgets);
  });

  testWidgets('07 - rota com argumento mostra detalhes', (tester) async {
    await open(tester, '/detalhes', arguments: lancamento());
    expect(find.text('Detalhes do lançamento'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
  });

  testWidgets('08 - cotação sem cache informa ausência', (tester) async {
    await open(tester, '/cotacoes');
    expect(find.text('Nenhum valor em cache'), findsOneWidget);
  });

  testWidgets('09 - formulário de categoria possui validação', (tester) async {
    await open(tester, '/nova-categoria');
    await tester.tap(find.text('Salvar categoria'));
    await tester.pump();
    expect(find.text('Informe o nome'), findsOneWidget);
  });

  testWidgets('10 - formulário de meta possui campos obrigatórios',
      (tester) async {
    await open(tester, '/nova-meta');
    await tester.ensureVisible(find.text('Salvar meta'));
    await tester.tap(find.text('Salvar meta'));
    await tester.pump();
    expect(find.text('Nome obrigatório'), findsOneWidget);
  });
}
