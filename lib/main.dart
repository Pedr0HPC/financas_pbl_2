import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'controllers/finance_controller.dart';
import 'datasources/local_store.dart';
import 'datasources/remote_api.dart';
import 'models/finance_models.dart';
import 'repositories/finance_repository.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/extra_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final client = http.Client();
  final controller = FinanceController(FinanceRepository(
      local: SqliteStore(), remote: HttpFinanceApi(client: client)));
  await controller.carregar();
  runApp(FinanceApp(controller: controller));
}

class FinanceApp extends StatelessWidget {
  final FinanceController controller;
  const FinanceApp({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Finanças PBL • Tema 06',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF216E66),
            inputDecorationTheme:
                const InputDecorationTheme(border: OutlineInputBorder())),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final args = settings.arguments;
          Widget page;
          switch (settings.name) {
            case '/':
              page = DashboardScreen(controller: controller);
            case '/lancamentos':
              page = TransactionsScreen(controller: controller);
            case '/novo':
              page = TransactionFormScreen(controller: controller);
            case '/editar':
              if (args is! Lancamento) return _invalidRoute(settings);
              page = TransactionFormScreen(controller: controller, item: args);
            case '/detalhes':
              if (args is! Lancamento) return _invalidRoute(settings);
              page =
                  TransactionDetailsScreen(controller: controller, item: args);
            case '/categorias':
              page = CategoriesScreen(controller: controller);
            case '/nova-categoria':
              page = CategoryFormScreen(
                  controller: controller,
                  categoria: args is Categoria ? args : null);
            case '/metas':
              page = GoalsScreen(controller: controller);
            case '/nova-meta':
              page = GoalFormScreen(
                  controller: controller,
                  meta: args is MetaFinanceira ? args : null);
            case '/relatorios':
              page = ReportsScreen(controller: controller);
            case '/cotacoes':
              page = ExchangeScreen(controller: controller);
            case '/sincronizacao':
              page = SyncScreen(controller: controller);
            case '/simulador':
              page = SimulatorScreen(controller: controller);
            case '/configuracoes':
              page = SettingsScreen(controller: controller);
            default:
              return _invalidRoute(settings);
          }
          return MaterialPageRoute<void>(
              settings: settings, builder: (_) => page);
        },
      );

  Route<void> _invalidRoute(RouteSettings settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const Scaffold(
          body:
              Center(child: Text('Rota inexistente ou argumento inválido.'))));
}
