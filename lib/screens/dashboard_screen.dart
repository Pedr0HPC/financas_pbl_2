import 'package:flutter/material.dart';
import '../controllers/finance_controller.dart';
import '../models/finance_models.dart';
import '../widgets/app_shell.dart';

class DashboardScreen extends StatelessWidget {
  final FinanceController controller;
  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Resumo financeiro',
      controller: controller,
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/novo'),
          icon: const Icon(Icons.add),
          label: const Text('Novo lançamento')),
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return RefreshIndicator(
                onRefresh: controller.carregar,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  const Text('Visão geral',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                      child: ListTile(
                          title: const Text('Saldo atual'),
                          subtitle: Text(brl(controller.saldo),
                              style: const TextStyle(fontSize: 28)),
                          leading: const Icon(
                              Icons.account_balance_wallet_outlined))),
                  Row(children: [
                    Expanded(
                        child: Card(
                            child: ListTile(
                                title: const Text('Receitas'),
                                subtitle: Text(brl(controller.receitas))))),
                    Expanded(
                        child: Card(
                            child: ListTile(
                                title: const Text('Despesas'),
                                subtitle: Text(brl(controller.despesas))))),
                  ]),
                  Card(
                      child: ListTile(
                          title: const Text('Pendências de envio'),
                          subtitle: Text('${controller.pendentes} registro(s)'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              Navigator.pushNamed(context, '/sincronizacao'))),
                  const SizedBox(height: 10),
                  const Text('Últimos lançamentos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (controller.lancamentos.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhum lançamento cadastrado.')),
                  for (final item in controller.lancamentos.take(5))
                    ListTile(
                        leading: Icon(item.tipo == 'receita'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward),
                        title: Text(item.descricao),
                        subtitle: Text(item.tipo),
                        trailing: Text(brl(item.valorCentavos)),
                        onTap: () => Navigator.pushNamed(context, '/detalhes',
                            arguments: item)),
                  const SizedBox(height: 80),
                ]));
          }));
}
