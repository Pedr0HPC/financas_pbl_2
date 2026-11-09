# Rastreamento de requisitos da AP2B (páginas 2, 3, 7 e 8 do enunciado)

| Exigência | Implementação preparada | Evidência sugerida |
|---|---|---|
| 10+ telas/rotas | 14 caminhos nomeados; 13 classes de páginas | `lib/main.dart`, abrir Drawer |
| Material Design 3 | `ThemeData(useMaterial3: true)` | `lib/main.dart` |
| Form/GlobalKey/TextEditingController | Formulários de lançamento, meta, categoria e simulador | `lib/screens/*form*`, `goals_screen.dart` |
| ListView.builder e Dismissible | Listas de lançamentos, metas, categorias | `transactions_screen.dart` |
| Argumentos de navegação | `/detalhes`, `/editar` verificam `Lancamento` | `onGenerateRoute` |
| Estado de sincronização e SnackBar | nuvem nos itens; alertar() | `transactions_screen.dart`, `app_shell.dart` |
| SQLite / relacionamento | `categorias` e `lancamentos` via FK | `local_store.dart` |
| insert/query/update/delete | API LocalStore, SqliteStore | `local_store.dart` |
| toMap/fromMap, JSON | Lancamento/Categoria/Meta/Cotacao | `finance_models.dart` |
| HTTP GET/POST/PUT/DELETE, timeout | AwesomeAPI/JSONPlaceholder | `remote_api.dart` |
| Repository/Offline-First | grava antes da rede; fila e fallback | `finance_repository.dart` |
| 20 testes de unidade | 30 domínio + 13 repositório + 7 HTTP | `test/domain_test.dart`, `test/repository_test.dart`, `test/remote_api_test.dart` |
| 5 testes de widget | 10 testWidgets | `test/widgets_test.dart` |
| README e Declaração de IA | tema, autores, arquitetura, endpoints, comandos, IA, refs | `README.md` |
| Arguição individual | perguntas e rastreio de código | `docs/PERGUNTAS_DEFESA.md` |

**Estado de validação:** arquivos criados, mas o ambiente de geração não possui Flutter SDK para execução. O grupo deve executar `flutter analyze`, `flutter test` e `flutter run` e solucionar quaisquer problemas antes da entrega.
