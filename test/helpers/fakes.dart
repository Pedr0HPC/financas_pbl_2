import 'package:financas_pbl_ap2b/datasources/local_store.dart';
import 'package:financas_pbl_ap2b/datasources/remote_api.dart';
import 'package:financas_pbl_ap2b/models/finance_models.dart';

class FakeStore implements LocalStore {
  final Map<String, Categoria> cats = {
    'geral': const Categoria(id: 'geral', nome: 'Geral'),
    'alimentacao': const Categoria(id: 'alimentacao', nome: 'Alimentação')
  };
  final Map<String, Lancamento> moves = {};
  final Map<String, MetaFinanceira> goals = {};
  final Map<String, Cotacao> rates = {};
  final List<String> history = [];
  @override
  Future<List<Categoria>> categorias() async => cats.values.toList();
  @override
  Future<void> salvarCategoria(Categoria item) async {
    cats[item.id] = item;
  }

  @override
  Future<void> excluirCategoria(String id) async {
    if (moves.values.any((x) => x.categoriaId == id)) {
      throw StateError('Categoria vinculada');
    }
    cats.remove(id);
  }

  @override
  Future<List<Lancamento>> lancamentos({bool incluirExcluidos = false}) async =>
      moves.values.where((e) => incluirExcluidos || !e.excluido).toList();
  @override
  Future<List<Lancamento>> pendentes() async =>
      moves.values.where((e) => !e.sincronizado).toList();
  @override
  Future<void> salvarLancamento(Lancamento item) async {
    if (!cats.containsKey(item.categoriaId)) {
      throw StateError('Categoria inexistente');
    }
    moves[item.id] = item;
  }

  @override
  Future<void> marcarExcluido(String id) async {
    final current = moves[id];
    if (current == null || current.excluido) {
      throw StateError('Lançamento inexistente');
    }
    moves[id] = current.copyWith(
        excluido: true, sincronizado: false, revisao: current.revisao + 1);
  }

  @override
  Future<bool> confirmarSync(String id, int revisao) async {
    final old = moves[id];
    if (old == null || old.revisao != revisao) return false;
    moves[id] = old.copyWith(sincronizado: true);
    return true;
  }

  @override
  Future<List<MetaFinanceira>> metas() async => goals.values.toList();
  @override
  Future<void> salvarMeta(MetaFinanceira item) async {
    goals[item.id] = item;
  }

  @override
  Future<void> excluirMeta(String id) async {
    goals.remove(id);
  }

  @override
  Future<void> salvarCotacoes(List<Cotacao> itens) async {
    for (final c in itens) {
      rates[c.par] = c;
    }
  }

  @override
  Future<List<Cotacao>> cotacoes() async => rates.values.toList();
  @override
  Future<void> logSync(String mensagem) async => history.add(mensagem);
  @override
  Future<List<String>> logs() async => history.reversed.toList();
}

class FakeRemote implements RemoteFinanceApi {
  bool fail = false;
  final List<Lancamento> sent = [];
  List<Cotacao> payload = [];
  @override
  Future<List<Cotacao>> buscarCotacoes() async {
    if (fail) throw Exception('sem rede');
    return payload;
  }

  @override
  Future<void> enviarLancamento(Lancamento item) async {
    if (fail) throw Exception('sem rede');
    sent.add(item);
  }
}

Lancamento lancamento(
        {String id = '1',
        String tipo = 'despesa',
        int valorCentavos = 2000,
        bool sincronizado = false,
        bool excluido = false,
        int revisao = 1}) =>
    Lancamento(
        id: id,
        descricao: 'Mercado',
        tipo: tipo,
        valorCentavos: valorCentavos,
        categoriaId: 'alimentacao',
        data: DateTime(2026, 11, 8),
        sincronizado: sincronizado,
        excluido: excluido,
        revisao: revisao);
