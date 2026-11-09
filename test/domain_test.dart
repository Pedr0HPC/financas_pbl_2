import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:financas_pbl_ap2b/models/finance_models.dart';
import 'package:financas_pbl_ap2b/domain/finance_rules.dart';
import 'helpers/fakes.dart';

void main() {
  group('Domínio e serialização', () {
    test('01 - valor inteiro BRL', () => expect(parseCentavos('10'), 1000));
    test('02 - valor decimal BRL', () => expect(parseCentavos('10,25'), 1025));
    test('03 - valor brasileiro com milhar',
        () => expect(parseCentavos('1.234,56'), 123456));
    test('04 - valor vazio lança erro',
        () => expect(() => parseCentavos(''), throwsFormatException));
    test('05 - valor negativo lança erro',
        () => expect(() => parseCentavos('-2'), throwsFormatException));
    test('06 - valor zero lança erro',
        () => expect(() => parseCentavos('0'), throwsFormatException));
    test('07 - valor alfabético lança erro',
        () => expect(() => parseCentavos('abc'), throwsFormatException));
    test('08 - moeda exibida com centavos',
        () => expect(brl(1025), 'R\$ 10,25'));
    test('09 - moeda negativa', () => expect(brl(-123), '-R\$ 1,23'));
    test('10 - saldo sem lançamentos é zero',
        () => expect(FinanceRules.saldo([]), 0));
    test('11 - receita aumenta saldo',
        () => expect(FinanceRules.saldo([lancamento(tipo: 'receita')]), 2000));
    test('12 - despesa reduz saldo',
        () => expect(FinanceRules.saldo([lancamento()]), -2000));
    test(
        '13 - saldo soma itens mistos',
        () => expect(
            FinanceRules.saldo([
              lancamento(id: 'a', tipo: 'receita', valorCentavos: 8000),
              lancamento(id: 'b', valorCentavos: 2500),
            ]),
            5500));
    test('14 - exclusão não entra no saldo',
        () => expect(FinanceRules.saldo([lancamento(excluido: true)]), 0));
    test(
        '15 - soma de receitas',
        () => expect(
            FinanceRules.totalReceitas([
              lancamento(id: 'a', tipo: 'receita', valorCentavos: 3000),
              lancamento(id: 'b', tipo: 'receita', valorCentavos: 8000),
              lancamento(id: 'c'),
            ]),
            11000));
    test(
        '16 - soma de despesas',
        () => expect(
            FinanceRules.totalDespesas([
              lancamento(id: 'a', tipo: 'receita'),
              lancamento(id: 'b', valorCentavos: 1200),
            ]),
            1200));
    test(
        '17 - total por categoria',
        () => expect(
            FinanceRules.despesasPorCategoria([
              lancamento(),
              lancamento(id: 'b', valorCentavos: 1000)
            ])['alimentacao'],
            3000));
    test(
        '18 - limite orçamentário excedido',
        () => expect(
            FinanceRules.excedeuLimite(
                const Categoria(
                    id: 'alimentacao',
                    nome: 'Alimentação',
                    limiteCentavos: 1000),
                [lancamento()]),
            isTrue));
    test(
        '19 - sem limite não excede',
        () => expect(
            FinanceRules.excedeuLimite(
                const Categoria(id: 'alimentacao', nome: 'Alimentação'),
                [lancamento()]),
            isFalse));
    test(
        '20 - juros 0% não alteram capital',
        () => expect(
            FinanceRules.jurosCompostos(
                capital: 1000, taxaMensal: 0, meses: 12),
            1000));
    test(
        '21 - juros compostos dois meses',
        () => expect(
            FinanceRules.jurosCompostos(
                capital: 1000, taxaMensal: 0.1, meses: 2),
            closeTo(1210, 0.0001)));
    test(
        '22 - taxa negativa lança erro',
        () => expect(
            () => FinanceRules.jurosCompostos(
                capital: 100, taxaMensal: -0.1, meses: 2),
            throwsArgumentError));
    test(
        '23 - meses negativos lançam erro',
        () => expect(
            () => FinanceRules.jurosCompostos(
                capital: 100, taxaMensal: 0.01, meses: -1),
            throwsArgumentError));
    test('24 - serialização SQLite conserva os dados', () {
      final item = lancamento();
      final novo = Lancamento.fromMap(item.toMap());
      expect(novo.valorCentavos, 2000);
      expect(novo.data, DateTime(2026, 11, 8));
    });
    test('25 - round-trip JSON', () {
      final item = Lancamento.fromJson(lancamento().toJson());
      expect(jsonDecode(item.toJson())['categoria_id'], 'alimentacao');
    });
    test('26 - tipo financeiro inválido lança erro',
        () => expect(() => lancamento(tipo: 'outro'), throwsArgumentError));
    test(
        '27 - categoria vazia lança erro',
        () => expect(
            () => Lancamento(
                id: 'z',
                descricao: 'X',
                valorCentavos: 100,
                tipo: 'receita',
                categoriaId: '',
                data: DateTime(2026)),
            throwsArgumentError));
    test('28 - copyWith preserva ID e altera sincronização', () {
      final anterior = lancamento();
      final atualizado = anterior.copyWith(sincronizado: true);
      expect(atualizado.id, anterior.id);
      expect(atualizado.sincronizado, true);
      expect(anterior.sincronizado, false);
    });
    test('29 - meta de economia calcula progresso', () {
      final meta = MetaFinanceira(
          id: 'm',
          nome: 'Viagem',
          alvoCentavos: 10000,
          acumuladoCentavos: 5000,
          prazo: DateTime(2027));
      expect(meta.progresso, .5);
    });
    test('30 - meta limita progresso a 100%', () {
      final meta = MetaFinanceira(
          id: 'm',
          nome: 'Viagem',
          alvoCentavos: 1000,
          acumuladoCentavos: 2000,
          prazo: DateTime(2027));
      expect(meta.progresso, 1);
    });
  });
}
