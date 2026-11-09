import '../models/finance_models.dart';

/// Evolução das regras da AP1B: receita adiciona, despesa subtrai,
/// metas e simulação de juros compostos permanecem no domínio Dart puro.
class FinanceRules {
  static int saldo(Iterable<Lancamento> itens) =>
      itens.where((x) => !x.excluido).fold<int>(
          0,
          (sum, x) =>
              sum + (x.tipo == 'receita' ? x.valorCentavos : -x.valorCentavos));

  static int totalReceitas(Iterable<Lancamento> itens) => itens
      .where((x) => !x.excluido && x.tipo == 'receita')
      .fold<int>(0, (s, x) => s + x.valorCentavos);

  static int totalDespesas(Iterable<Lancamento> itens) => itens
      .where((x) => !x.excluido && x.tipo == 'despesa')
      .fold<int>(0, (s, x) => s + x.valorCentavos);

  static Map<String, int> despesasPorCategoria(Iterable<Lancamento> itens) {
    final resultado = <String, int>{};
    for (final x in itens.where((x) => !x.excluido && x.tipo == 'despesa')) {
      resultado.update(x.categoriaId, (old) => old + x.valorCentavos,
          ifAbsent: () => x.valorCentavos);
    }
    return resultado;
  }

  /// A fórmula M=C*(1+i)^n não altera o valor real da meta.
  static double jurosCompostos(
      {required double capital,
      required double taxaMensal,
      required int meses}) {
    if (capital < 0 ||
        taxaMensal < 0 ||
        meses < 0 ||
        !capital.isFinite ||
        !taxaMensal.isFinite) {
      throw ArgumentError('Parâmetros de juros compostos inválidos.');
    }
    var montante = capital;
    for (var i = 0; i < meses; i++) {
      montante *= (1 + taxaMensal);
    }
    return montante;
  }

  static bool excedeuLimite(Categoria c, Iterable<Lancamento> itens) =>
      c.limiteCentavos > 0 &&
      (despesasPorCategoria(itens)[c.id] ?? 0) > c.limiteCentavos;
}
