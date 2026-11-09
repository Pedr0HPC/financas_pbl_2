import 'package:flutter/foundation.dart';
import '../domain/finance_rules.dart';
import '../models/finance_models.dart';
import '../repositories/finance_repository.dart';

class FinanceController extends ChangeNotifier {
  final FinanceRepository repository;
  FinanceController(this.repository);
  List<Lancamento> lancamentos = [];
  List<Categoria> categorias = [];
  List<MetaFinanceira> metas = [];
  List<Cotacao> cotacoes = [];
  List<String> logs = [];
  int pendentes = 0;
  bool carregando = false;
  bool sincronizando = false;
  String? mensagem;
  int get saldo => FinanceRules.saldo(lancamentos);
  int get receitas => FinanceRules.totalReceitas(lancamentos);
  int get despesas => FinanceRules.totalDespesas(lancamentos);

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();
    try {
      // Todas as leituras de UI são atendidas pela fonte de dados local.
      lancamentos = await repository.listar();
      categorias = await repository.categorias();
      metas = await repository.metas();
      cotacoes = await repository.cotacoesLocais();
      logs = await repository.logs();
      pendentes = (await repository.pendentes()).length;
      mensagem = null;
    } catch (e) {
      mensagem = 'Erro no armazenamento local: $e';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> salvarLancamento(Lancamento item) async {
    await repository.salvarLancamento(item);
    await carregar();
  }

  Future<void> excluirLancamento(String id) async {
    await repository.excluirLancamento(id);
    await carregar();
  }

  Future<void> salvarCategoria(Categoria item) async {
    await repository.salvarCategoria(item);
    await carregar();
  }

  Future<void> excluirCategoria(String id) async {
    await repository.excluirCategoria(id);
    await carregar();
  }

  Future<void> salvarMeta(MetaFinanceira item) async {
    await repository.salvarMeta(item);
    await carregar();
  }

  Future<void> excluirMeta(String id) async {
    await repository.excluirMeta(id);
    await carregar();
  }

  Future<SyncResult> sincronizar() async {
    sincronizando = true;
    notifyListeners();
    try {
      final resultado = await repository.sincronizar();
      await carregar();
      return resultado;
    } finally {
      sincronizando = false;
      notifyListeners();
    }
  }

  Future<void> atualizarCotacoes() async {
    cotacoes = await repository.atualizarCotacoes();
    notifyListeners();
  }
}
