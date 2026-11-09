import 'dart:convert';

/// Valores em centavos evitam a soma imprecisa de números decimais binários.
int parseCentavos(String input) {
  var value = input.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (value.isEmpty) throw const FormatException('Informe um valor.');
  if (value.contains(',')) {
    value = value.replaceAll('.', '').replaceAll(',', '.');
  }
  final parsed = double.tryParse(value);
  if (parsed == null || !parsed.isFinite || parsed <= 0) {
    throw const FormatException('O valor deve ser positivo.');
  }
  return (parsed * 100).round();
}

String brl(int cents) {
  final negative = cents < 0;
  final absolute = cents.abs();
  final integer = (absolute ~/ 100).toString();
  final group =
      integer.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  return '${negative ? '-' : ''}R\$ $group,${(absolute % 100).toString().padLeft(2, '0')}';
}

String newId() => 'FIN-${DateTime.now().microsecondsSinceEpoch}';

class Categoria {
  final String id;
  final String nome;
  final int limiteCentavos;
  const Categoria(
      {required this.id, required this.nome, this.limiteCentavos = 0});
  Map<String, Object?> toMap() =>
      {'id': id, 'nome': nome, 'limite_centavos': limiteCentavos};
  factory Categoria.fromMap(Map<String, Object?> map) => Categoria(
        id: map['id'] as String,
        nome: map['nome'] as String,
        limiteCentavos: (map['limite_centavos'] as num?)?.toInt() ?? 0,
      );
}

class Lancamento {
  final String id;
  final String descricao;
  final int valorCentavos;
  final String tipo; // 'receita' ou 'despesa'
  final String categoriaId;
  final DateTime data;
  final bool sincronizado;
  final bool excluido;
  final int revisao;

  Lancamento(
      {required this.id,
      required this.descricao,
      required this.valorCentavos,
      required this.tipo,
      required this.categoriaId,
      required this.data,
      this.sincronizado = false,
      this.excluido = false,
      this.revisao = 1}) {
    if (descricao.trim().isEmpty) throw ArgumentError('Descrição obrigatória.');
    if (valorCentavos <= 0) throw ArgumentError('Valor deve ser positivo.');
    if (tipo != 'receita' && tipo != 'despesa') {
      throw ArgumentError('Tipo inválido.');
    }
    if (categoriaId.trim().isEmpty) {
      throw ArgumentError('Categoria obrigatória.');
    }
  }

  Lancamento copyWith(
          {String? descricao,
          int? valorCentavos,
          String? tipo,
          String? categoriaId,
          DateTime? data,
          bool? sincronizado,
          bool? excluido,
          int? revisao}) =>
      Lancamento(
          id: id,
          descricao: descricao ?? this.descricao,
          valorCentavos: valorCentavos ?? this.valorCentavos,
          tipo: tipo ?? this.tipo,
          categoriaId: categoriaId ?? this.categoriaId,
          data: data ?? this.data,
          sincronizado: sincronizado ?? this.sincronizado,
          excluido: excluido ?? this.excluido,
          revisao: revisao ?? this.revisao);

  Map<String, Object?> toMap() => {
        'id': id,
        'descricao': descricao,
        'valor_centavos': valorCentavos,
        'tipo': tipo,
        'categoria_id': categoriaId,
        'data': data.toIso8601String(),
        'sincronizado': sincronizado ? 1 : 0,
        'excluido': excluido ? 1 : 0,
        'revisao': revisao,
      };

  factory Lancamento.fromMap(Map<String, Object?> map) => Lancamento(
        id: map['id'] as String,
        descricao: map['descricao'] as String,
        valorCentavos: (map['valor_centavos'] as num).toInt(),
        tipo: map['tipo'] as String,
        categoriaId: map['categoria_id'] as String,
        data: DateTime.parse(map['data'] as String),
        sincronizado: map['sincronizado'] == true || map['sincronizado'] == 1,
        excluido: map['excluido'] == true || map['excluido'] == 1,
        revisao: (map['revisao'] as num?)?.toInt() ?? 1,
      );

  String toJson() => jsonEncode(toMap());
  factory Lancamento.fromJson(String json) =>
      Lancamento.fromMap(Map<String, Object?>.from(jsonDecode(json) as Map));
}

class MetaFinanceira {
  final String id;
  final String nome;
  final int alvoCentavos;
  final int acumuladoCentavos;
  final DateTime prazo;
  const MetaFinanceira(
      {required this.id,
      required this.nome,
      required this.alvoCentavos,
      required this.acumuladoCentavos,
      required this.prazo});
  double get progresso => alvoCentavos <= 0
      ? 0.0
      : (acumuladoCentavos / alvoCentavos).clamp(0.0, 1.0).toDouble();
  Map<String, Object?> toMap() => {
        'id': id,
        'nome': nome,
        'alvo_centavos': alvoCentavos,
        'acumulado_centavos': acumuladoCentavos,
        'prazo': prazo.toIso8601String()
      };
  factory MetaFinanceira.fromMap(Map<String, Object?> map) => MetaFinanceira(
      id: map['id'] as String,
      nome: map['nome'] as String,
      alvoCentavos: (map['alvo_centavos'] as num).toInt(),
      acumuladoCentavos: (map['acumulado_centavos'] as num).toInt(),
      prazo: DateTime.parse(map['prazo'] as String));
}

class Cotacao {
  final String par;
  final double valor;
  final DateTime atualizadoEm;
  const Cotacao(
      {required this.par, required this.valor, required this.atualizadoEm});
  Map<String, Object?> toMap() => {
        'par': par,
        'valor': valor,
        'atualizado_em': atualizadoEm.toIso8601String()
      };
  factory Cotacao.fromMap(Map<String, Object?> map) => Cotacao(
      par: map['par'] as String,
      valor: (map['valor'] as num).toDouble(),
      atualizadoEm: DateTime.parse(map['atualizado_em'] as String));
}
