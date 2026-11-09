import 'package:flutter/material.dart';
import '../controllers/finance_controller.dart';

class AppShell extends StatelessWidget {
  final String title;
  final Widget body;
  final FinanceController controller;
  final Widget? floatingActionButton;
  const AppShell(
      {super.key,
      required this.title,
      required this.body,
      required this.controller,
      this.floatingActionButton});

  static const links = <(String, String, IconData)>[
    ('/', 'Resumo', Icons.dashboard_outlined),
    ('/lancamentos', 'Lançamentos', Icons.receipt_long_outlined),
    ('/novo', 'Novo lançamento', Icons.add_circle_outline),
    ('/categorias', 'Categorias', Icons.category_outlined),
    ('/metas', 'Metas', Icons.flag_outlined),
    ('/relatorios', 'Relatórios', Icons.bar_chart_outlined),
    ('/cotacoes', 'Cotação de moedas', Icons.currency_exchange),
    ('/sincronizacao', 'Sincronização', Icons.sync),
    ('/simulador', 'Juros compostos', Icons.calculate_outlined),
    ('/configuracoes', 'Configurações', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: [
          AnimatedBuilder(
              animation: controller,
              builder: (context, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Tooltip(
                      message: '${controller.pendentes} pendente(s)',
                      child: Icon(controller.pendentes == 0
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_upload_outlined)))),
        ]),
        drawer: Drawer(
            child: SafeArea(
                child: ListView(children: [
          const ListTile(
              title: Text('Finanças PBL'), subtitle: Text('Tema 06 • AP2B')),
          const Divider(),
          for (final item in links)
            ListTile(
                leading: Icon(item.$3),
                title: Text(item.$2),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, item.$1);
                }),
        ]))),
        body: SafeArea(child: body),
        floatingActionButton: floatingActionButton,
      );
}

void alertar(BuildContext context, String mensagem) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}
