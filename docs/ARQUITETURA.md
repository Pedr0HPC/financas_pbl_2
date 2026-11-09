# Arquitetura e decisões técnicas — Tema 06, AP2B

## 1. Contexto
O Marco 1 operava em Dart puro. Na AP2B, a UI Flutter foi adicionada sem permitir que um widget consulte tabelas SQL ou acesse URLs HTTP diretamente.

## 2. Fluxo de dados

```text
[Tela Material 3 / Formulários / ListView]
                  |
                  v
[FinanceController - ChangeNotifier, estado reativo]
                  |
                  v
[FinanceRepository - orquestração Offline-First]
       |                             |
       v                             v
[LocalStore/SqliteStore]       [RemoteFinanceApi]
       |                             |           |
       v                             v           v
[SQLite: categorias,             AwesomeAPI   JSONPlaceholder
 lancamentos, metas,              GET /câmbio  POST/PUT/DELETE
 cotacoes, logs_sync]                        (mock)
```

O SQLite é a **Single Source of Truth**. O Repository é responsável por realizar gravações locais e, quando explicitamente solicitado, tentar enviar pendências e atualizar cotações. A UI atualiza-se via `ChangeNotifier`/`AnimatedBuilder` após novas leituras locais.

## 3. Entidades e relacionamento

```text
CATEGORIAS (id PK, nome UNIQUE, limite_centavos)
    1  ─────────────────────< N
LANCAMENTOS (id PK, descricao, valor_centavos, tipo,
             categoria_id FK, data, sincronizado, excluido, revisao)

METAS (id PK, nome, alvo_centavos, acumulado_centavos, prazo)
COTACOES (par PK, valor, atualizado_em)
LOGS_SYNC (id PK, mensagem, criado_em)
```

O relacionamento categorias/lancamentos é uma FK real habilitada com `PRAGMA foreign_keys = ON`. Excluir uma categoria com lançamentos existentes gera falha de integridade, tratada na interface.

## 4. Casos de uso

### 4.1 Cadastrar receita/despesa sem rede
1. `TransactionFormScreen` valida `Form` e cria `Lancamento`.
2. `FinanceController.salvarLancamento` chama o repositório.
3. `FinanceRepository.salvarLancamento` grava no SQLite com `sincronizado = 0`.
4. Controller recarrega lista **do banco**, notifica a UI.
5. A rede não participa: a operação funciona em modo avião.

### 4.2 Sincronização voluntária
1. A tela de sincronização chama `FinanceController.sincronizar()`.
2. Repositório busca `LocalStore.pendentes()`.
3. Escolhe POST se revisão=1, PUT se edição e DELETE se excluído.
4. `HttpFinanceApi` faz requisição JSON com timeout de 5 segundos.
5. HTTP 2xx: chama `confirmarSync(id, revisao)`; se versão mudou, mantém pendente.
6. Exceção de rede/timeout/status incorreto: registra log e mantém `sincronizado=0`.

**Limitação conhecida:** JSONPlaceholder é uma API fake. Não guarda o dado de modo duradouro. Assim, a confirmação de envio é meramente demonstrativa e não representa sincronização entre dois usuários/dispositivos.

### 4.3 Exclusão Offline-First
A exclusão usa `excluido=1`, `sincronizado=0` e incrementa `revisao`. O item desaparece das listas mas **permanece no SQLite** até que o repositório envie a operação DELETE. Após sucesso de demonstração, o tombstone continua armazenado com sincronizado=1 (para preservar histórico). Essa retenção também demonstra a fila de eventos, mas exigiria política de limpeza em produção.

### 4.4 Atualização de cotação
1. O Repository tenta GET `/json/last/USD-BRL,EUR-BRL`.
2. Checa status, converte JSON, valida `bid` numérico e positivo.
3. Grava os dois pares na tabela cotacoes.
4. A tela obtém cotação via leitura local. Se HTTP falhar, a última cotação em cache continua visível, com o timestamp antigo. Se nunca houver cache, não há cotação para mostrar.

## 5. Exceções e consistência

- Validação de negócio: descrição obrigatória; valor positivo; `tipo` só receita/despesa; categoria obrigatória.
- Moeda: centavos `int`; conversão na borda (formulário), evitando erros de centavos por `double` em somas.
- Erro de rede: capturado no Repository, não apaga nem altera registros locais não sincronizados.
- `revisao`: controle otimista. Alterações após envio iniciado impedem confirmar versão defasada.
- Chave estrangeira protege a referência categoria -> lançamento.
- Todo log de sincronização fica no dispositivo, para diagnóstico.

## 6. Escolhas de UI e Flutter

- `StatelessWidget` para páginas orientadas a Controller; `StatefulWidget` para formulários e controllers de campos.
- `MaterialApp(onGenerateRoute)` permite 14 rotas com validação de argumentos de navegação.
- `ChangeNotifier` notifica `AnimatedBuilder` para atualizar totalizadores e listas.
- `Scaffold`/`AppBar`/`Drawer` são partes do shell reutilizável.
- `Dismissible` chama confirmação antes de exclusão, reduzindo erros de gesto.
- `SnackBar` expõe erros e sucessos relevantes sem bloquear o formulário.

## 7. Testabilidade

A UI não depende diretamente do `SqliteStore` ou `HttpFinanceApi`, mas do `FinanceController` que recebe um `FinanceRepository`. Este recebe `LocalStore` e `RemoteFinanceApi`. Os testes usam `FakeStore` e `FakeRemote`, permitindo simular perda de conexão sem emulador nem conexão real.

Existem **30 testes de domínio**, **13 testes de repositório**, **7 testes de HTTP MockClient** e **10 testes de widget**, definidos no código. A execução correta deve ser comprovada na máquina do grupo usando `flutter test`.

## 8. Limites e próximos passos

- Mock remoto não persiste dados financeiros (limitação deliberada, não divulgar como backup).
- Não há autenticação/criptografia específica, resolução de conflito multiusuário, reconciliação server-driven ou sincronização automática em background.
- Não há tratamento para migração de versões de banco, além da versão inicial 1.
- A regra original da AP1B para impedir despesa com saldo insuficiente foi alterada para permitir saldo negativo; justificar como livro-caixa de despesas efetivas.
- Implementação preparada para Android; diretórios de plataforma são gerados com `flutter create` e devem ser incluídos na entrega final.
