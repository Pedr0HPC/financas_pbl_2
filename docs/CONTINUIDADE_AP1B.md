# Continuidade da AP1B para a AP2B

## Origem
Projeto original: https://github.com/Pedr0HPC/financas_pbl (Marco 1, Dart puro).

A estrutura consultada no repositório inicial tinha `lib/models/models.dart`, `lib/services/services.dart`, `lib/exceptions/exceptions.dart`, `bin/main.dart`, `README.md` e `ENVIRONMENT_REPORT.md`. O objetivo acadêmico da AP1B era demonstrar orientação a objetos e regras financeiras sem UI.

## Funcionalidades preservadas conceitualmente

| AP1B | AP2B |
|---|---|
| Receitas e Despesas polimórficas impactam saldo | `FinanceRules.saldo`, `totalReceitas`, `totalDespesas` sobre lançamentos armazenados |
| Categoria de despesa | `Categoria` relacional no SQLite e limite orçamentário por categoria |
| `GerenciadorFinanceiro.calcularGastosPorCategoria` | `FinanceRules.despesasPorCategoria` e página de relatórios |
| Meta de economia e progresso | `MetaFinanceira` persistida no banco local |
| `MetaEconomia.simularJurosCompostos` | `FinanceRules.jurosCompostos` e tela do simulador |
| Construtores factory para Map | `Lancamento.fromMap`, `fromJson`, `toMap`, `toJson` |
| Dart puro e null safety | Domínio puro, testes sem widget/banco e classes tipadas |

**Importante para a defesa:** o projeto AP2B foi uma *reestruturação e reimplementação baseada nas regras da AP1B*, não um import direto das classes antigas. A implementação original evitava despesas que causassem saldo negativo; a AP2B utiliza saldo contábil, permitindo saldo negativo. É uma mudança explícita de regra de negócio. Se o professor exigir preservação literal do núcleo original, a equipe deve portar os arquivos originais e integrar seus contratos, em vez de afirmar que eles estão idênticos.

## Qual foi o ganho arquitetural?

Na AP1B a memória do processo guardava as informações, perdidas ao fechar o executável. Agora o banco `sqflite` mantém receitas, despesas, categorias, metas, cache e histórico entre sessões. A UI é reativa e a sincronização HTTP desacoplada da interface.

## Como demonstrar essa evolução em 40 segundos

> No primeiro bimestre desenvolvemos um núcleo de finanças em Dart, com receitas, despesas, categorias, metas e juros compostos. Agora adaptamos essas regras para Flutter e SQLite. Os dados são salvos primeiro no dispositivo, aparecem mesmo sem rede e ficam com status pendente. Uma camada Repository tenta enviar registros para uma API simulada e consulta cotações reais com cache local. Também adicionamos telas e testes automatizados.
