import 'package:flutter_test/flutter_test.dart';
import 'package:financas_pbl_ap2b/models/finance_models.dart';
import 'package:financas_pbl_ap2b/repositories/finance_repository.dart';
import 'helpers/fakes.dart';

void main() {
  late FakeStore local;
  late FakeRemote remote;
  late FinanceRepository repo;
  setUp(() {
    local = FakeStore();
    remote = FakeRemote();
    repo = FinanceRepository(local: local, remote: remote);
  });
  group('Repositório offline-first', () {
    test('31 - salva primeiro local sem depender da rede', () async {
      remote.fail = true;
      await repo.salvarLancamento(lancamento());
      expect((await repo.listar()).length, 1);
      expect((await repo.pendentes()).length, 1);
    });
    test('32 - falha HTTP não remove o lançamento', () async {
      remote.fail = true;
      await repo.salvarLancamento(lancamento());
      final result = await repo.sincronizar();
      expect(result.falhas, 1);
      expect((await repo.listar()).length, 1);
      expect((await repo.pendentes()).length, 1);
    });
    test('33 - sucesso confirma a versão enviada', () async {
      await repo.salvarLancamento(lancamento());
      final result = await repo.sincronizar();
      expect(result.enviados, 1);
      expect((await repo.pendentes()).length, 0);
    });
    test('34 - excluir cria tombstone pendente', () async {
      await repo.salvarLancamento(lancamento());
      await repo.excluirLancamento('1');
      expect((await repo.listar()), isEmpty);
      final pending = await repo.pendentes();
      expect(pending.single.excluido, isTrue);
    });
    test('35 - exclusão pendente é enviada', () async {
      await repo.salvarLancamento(lancamento());
      await repo.excluirLancamento('1');
      await repo.sincronizar();
      expect(remote.sent.single.excluido, isTrue);
    });
    test('36 - edição aumenta revisão e repõe pendência', () async {
      await repo.salvarLancamento(lancamento());
      await repo.sincronizar();
      await repo.salvarLancamento(lancamento(valorCentavos: 3000));
      expect((await repo.pendentes()).single.revisao, 2);
      expect((await repo.listar()).single.valorCentavos, 3000);
    });
    test('37 - cotação usa cache quando falta internet', () async {
      await local.salvarCotacoes(
          [Cotacao(par: 'USDBRL', valor: 5.0, atualizadoEm: DateTime(2026))]);
      remote.fail = true;
      final quote = await repo.atualizarCotacoes();
      expect(quote.single.valor, 5);
    });
    test('38 - cotação HTTP salva no cache', () async {
      remote.payload = [
        Cotacao(par: 'EURBRL', valor: 6.5, atualizadoEm: DateTime(2026))
      ];
      await repo.atualizarCotacoes();
      expect((await repo.cotacoesLocais()).single.par, 'EURBRL');
    });
    test('39 - log registra erro de sincronização', () async {
      remote.fail = true;
      await repo.salvarLancamento(lancamento());
      await repo.sincronizar();
      expect((await repo.logs()).single, contains('Pendente'));
    });
    test('40 - sincronizar fila vazia retorna zero', () async {
      final result = await repo.sincronizar();
      expect(result.enviados, 0);
      expect(result.falhas, 0);
    });
    test('41 - categoria salva separadamente', () async {
      await repo.salvarCategoria(const Categoria(id: 'lazer', nome: 'Lazer'));
      expect((await repo.categorias()).any((c) => c.id == 'lazer'), isTrue);
    });
    test('42 - meta inválida é recusada', () async {
      expect(
          () => repo.salvarMeta(MetaFinanceira(
              id: 'x',
              nome: '',
              alvoCentavos: 0,
              acumuladoCentavos: 0,
              prazo: DateTime(2027))),
          throwsArgumentError);
    });
    test('43 - impede confirmar revisão antiga', () async {
      await repo.salvarLancamento(lancamento());
      await repo.salvarLancamento(lancamento(valorCentavos: 3000));
      expect(await local.confirmarSync('1', 1), isFalse);
      expect((await repo.pendentes()).length, 1);
    });
  });
}
