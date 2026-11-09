import '../datasources/local_store.dart';
import '../datasources/remote_api.dart';
import '../models/finance_models.dart';

class SyncResult {
  final int enviados;
  final int falhas;
  const SyncResult(this.enviados, this.falhas);
}

/// Único ponto de entrada da UI. Lê sempre SQLite e escreve primeiro nele.
class FinanceRepository {
  final LocalStore local;
  final RemoteFinanceApi remote;
  FinanceRepository({required this.local, required this.remote});

  Future<List<Lancamento>> listar() => local.lancamentos();
  Future<List<Categoria>> categorias() => local.categorias();
  Future<List<MetaFinanceira>> metas() => local.metas();
  Future<List<Lancamento>> pendentes() => local.pendentes();
  Future<List<String>> logs() => local.logs();
  Future<List<Cotacao>> cotacoesLocais() => local.cotacoes();

  /// Salva sem aguardar rede: o chamador pode tentar sincronizar separadamente.
  Future<void> salvarLancamento(Lancamento item) async {
    final atuais = await local.lancamentos(incluirExcluidos: true);
    final antigos = atuais.where((x) => x.id == item.id);
    final revisao = antigos.isEmpty ? 1 : antigos.first.revisao + 1;
    await local.salvarLancamento(
        item.copyWith(sincronizado: false, excluido: false, revisao: revisao));
  }

  Future<void> excluirLancamento(String id) => local.marcarExcluido(id);
  Future<void> salvarCategoria(Categoria c) => local.salvarCategoria(c);
  Future<void> excluirCategoria(String id) => local.excluirCategoria(id);
  Future<void> salvarMeta(MetaFinanceira meta) {
    if (meta.nome.trim().isEmpty ||
        meta.alvoCentavos <= 0 ||
        meta.acumuladoCentavos < 0) {
      throw ArgumentError('Meta financeira inválida.');
    }
    return local.salvarMeta(meta);
  }

  Future<void> excluirMeta(String id) => local.excluirMeta(id);

  Future<SyncResult> sincronizar() async {
    final itens = await local.pendentes();
    var sucessos = 0;
    var falhas = 0;
    for (final item in itens) {
      try {
        await remote.enviarLancamento(item);
        final confirmou = await local.confirmarSync(item.id, item.revisao);
        if (confirmou) {
          sucessos++;
          await local.logSync(
              'Envio demonstrativo OK: ${item.id} (rev. ${item.revisao})');
        } else {
          falhas++;
          await local.logSync('Versão alterada durante envio: ${item.id}');
        }
      } catch (e) {
        // O registro permanece no SQLite com sincronizado=false.
        falhas++;
        await local.logSync('Pendente ${item.id}: $e');
      }
    }
    return SyncResult(sucessos, falhas);
  }

  /// Em caso de falha HTTP, devolve cache local. Nunca bloqueia os lançamentos.
  Future<List<Cotacao>> atualizarCotacoes() async {
    try {
      final dados = await remote.buscarCotacoes();
      await local.salvarCotacoes(dados);
      return await local.cotacoes();
    } catch (e) {
      await local.logSync('Cotação offline: $e');
      return await local.cotacoes();
    }
  }
}
