import 'package:flutter/material.dart';
import '../controllers/finance_controller.dart';
import '../domain/finance_rules.dart';
import '../models/finance_models.dart';
import '../widgets/app_shell.dart';

class ReportsScreen extends StatelessWidget {
  final FinanceController controller;
  const ReportsScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Relatórios financeiros',
      controller: controller,
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final gastos =
                FinanceRules.despesasPorCategoria(controller.lancamentos);
            return ListView(padding: const EdgeInsets.all(16), children: [
              ListTile(
                  title: const Text('Saldo'),
                  trailing: Text(brl(controller.saldo))),
              ListTile(
                  title: const Text('Total de receitas'),
                  trailing: Text(brl(controller.receitas))),
              ListTile(
                  title: const Text('Total de despesas'),
                  trailing: Text(brl(controller.despesas))),
              const Divider(),
              const Text('Despesas por categoria',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (gastos.isEmpty) const Text('Nenhuma despesa para exibir.'),
              for (final entry in gastos.entries)
                Builder(builder: (context) {
                  final cat =
                      controller.categorias.where((c) => c.id == entry.key);
                  final c = cat.isEmpty ? null : cat.first;
                  return Card(
                      child: ListTile(
                          title: Text(c?.nome ?? entry.key),
                          subtitle: Text(c != null &&
                                  FinanceRules.excedeuLimite(
                                      c, controller.lancamentos)
                              ? 'Orçamento excedido'
                              : 'Dentro do limite ou sem limite definido'),
                          trailing: Text(brl(entry.value))));
                }),
            ]);
          }));
}

class ExchangeScreen extends StatelessWidget {
  final FinanceController controller;
  const ExchangeScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Cotações de moedas',
      controller: controller,
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) =>
              ListView(padding: const EdgeInsets.all(16), children: [
                const Text('Fonte: AwesomeAPI • USD/BRL e EUR/BRL'),
                const Text(
                    'Os últimos valores consultados ficam armazenados em SQLite.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                    onPressed: () async {
                      await controller.atualizarCotacoes();
                      if (context.mounted) {
                        alertar(
                            context,
                            controller.cotacoes.isEmpty
                                ? 'Sem conexão e sem cotação em cache.'
                                : 'Cotação disponível (rede ou cache local).');
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar cotação')),
                if (controller.cotacoes.isEmpty)
                  const ListTile(
                      title: Text('Nenhum valor em cache'),
                      subtitle: Text('A primeira consulta requer internet.')),
                for (final c in controller.cotacoes)
                  Card(
                      child: ListTile(
                          title: Text(c.par),
                          subtitle:
                              Text('Consultado em ${c.atualizadoEm.toLocal()}'),
                          trailing: Text('R\$ ${c.valor.toStringAsFixed(4)}'))),
              ])));
}

class SyncScreen extends StatelessWidget {
  final FinanceController controller;
  const SyncScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Diagnóstico de sincronização',
      controller: controller,
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) =>
              ListView(padding: const EdgeInsets.all(16), children: [
                Card(
                    child: ListTile(
                        title: const Text('Lançamentos pendentes'),
                        subtitle:
                            Text('${controller.pendentes} aguardando envio'),
                        leading: Icon(controller.pendentes == 0
                            ? Icons.cloud_done
                            : Icons.cloud_upload))),
                const Text(
                    'A sincronização utiliza JSONPlaceholder, um endpoint fictício. '
                    'Sucesso HTTP não significa backup permanente dos dados.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: controller.sincronizando
                        ? null
                        : () async {
                            final resultado = await controller.sincronizar();
                            if (context.mounted) {
                              alertar(context,
                                  '${resultado.enviados} enviados ao mock; ${resultado.falhas} pendentes/falhas.');
                            }
                          },
                    icon: const Icon(Icons.sync),
                    label: Text(controller.sincronizando
                        ? 'Enviando...'
                        : 'Sincronizar agora')),
                const SizedBox(height: 20),
                const Text('Histórico de tentativas',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (controller.logs.isEmpty)
                  const Text('Nenhum envio realizado.'),
                for (final texto in controller.logs)
                  ListTile(dense: true, title: Text(texto)),
              ])));
}

class SimulatorScreen extends StatefulWidget {
  final FinanceController controller;
  const SimulatorScreen({super.key, required this.controller});
  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final capital = TextEditingController(text: '1000');
  final taxa = TextEditingController(text: '1');
  final meses = TextEditingController(text: '12');
  final form = GlobalKey<FormState>();
  double? resultado;
  @override
  void dispose() {
    capital.dispose();
    taxa.dispose();
    meses.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Simulador de juros',
      controller: widget.controller,
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Mantém a simulação de juros compostos da AP1B.'),
            for (final field in [
              (capital, 'Capital inicial (R\$)'),
              (taxa, 'Taxa mensal (%)'),
              (meses, 'Meses')
            ])
              TextFormField(
                  controller: field.$1,
                  decoration: InputDecoration(labelText: field.$2),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      double.tryParse((v ?? '').replaceAll(',', '.')) == null
                          ? 'Informe um número válido'
                          : null),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: () {
                  if (!form.currentState!.validate()) return;
                  try {
                    setState(() => resultado = FinanceRules.jurosCompostos(
                        capital:
                            double.parse(capital.text.replaceAll(',', '.')),
                        taxaMensal:
                            double.parse(taxa.text.replaceAll(',', '.')) / 100,
                        meses: int.parse(meses.text)));
                  } catch (e) {
                    alertar(context, 'Valor inválido: $e');
                  }
                },
                child: const Text('Calcular projeção')),
            if (resultado != null)
              Card(
                  child: ListTile(
                      title: const Text('Montante projetado'),
                      subtitle: Text(brl((resultado! * 100).round())))),
          ])));
}

class SettingsScreen extends StatelessWidget {
  final FinanceController controller;
  const SettingsScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Configurações',
      controller: controller,
      body: ListView(children: [
        const ListTile(
            title: Text('Tema 06 • Computação Móvel AP2B'),
            subtitle: Text('Versão acadêmica Flutter + SQLite + HTTP')),
        const ListTile(
            title: Text('Armazenamento'),
            subtitle:
                Text('Dados financeiros registrados somente no SQLite local.')),
        const ListTile(
            title: Text('API de envio'),
            subtitle: Text(
                'JSONPlaceholder: simulação sem persistência remota real.')),
        ListTile(
            title: const Text('Atualizar dados locais'),
            trailing: const Icon(Icons.refresh),
            onTap: () async {
              await controller.carregar();
              if (context.mounted) {
                alertar(context, 'Dados locais atualizados.');
              }
            }),
        const ListTile(
            title: Text('Segurança'),
            subtitle: Text(
                'Não armazene dados bancários reais nesta demonstração acadêmica.')),
      ]));
}
