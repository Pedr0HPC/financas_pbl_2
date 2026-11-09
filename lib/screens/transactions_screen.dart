import 'package:flutter/material.dart';
import '../controllers/finance_controller.dart';
import '../models/finance_models.dart';
import '../widgets/app_shell.dart';

class TransactionsScreen extends StatelessWidget {
  final FinanceController controller;
  const TransactionsScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Lançamentos',
      controller: controller,
      floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/novo'),
          tooltip: 'Adicionar',
          child: const Icon(Icons.add)),
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => controller.lancamentos.isEmpty
              ? const Center(
                  child: Text('Nenhum lançamento. Use + para adicionar.'))
              : ListView.builder(
                  itemCount: controller.lancamentos.length,
                  itemBuilder: (context, index) {
                    final item = controller.lancamentos[index];
                    return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                            color: Theme.of(context).colorScheme.errorContainer,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.all(20),
                            child: const Icon(Icons.delete_outline)),
                        confirmDismiss: (_) async =>
                            (await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                        title:
                                            const Text('Excluir lançamento?'),
                                        content: const Text(
                                            'A exclusão será registrada localmente e enviada quando houver rede.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancelar')),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Excluir'))
                                        ]))) ??
                            false,
                        onDismissed: (_) async {
                          try {
                            await controller.excluirLancamento(item.id);
                          } catch (e) {
                            if (context.mounted) alertar(context, '$e');
                          }
                        },
                        child: ListTile(
                            leading: Icon(item.tipo == 'receita'
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline),
                            title: Text(item.descricao),
                            subtitle: Text(
                                '${item.tipo} • ${item.data.day}/${item.data.month}/${item.data.year}'),
                            trailing:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                  item.sincronizado
                                      ? Icons.cloud_done_outlined
                                      : Icons.cloud_upload_outlined,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(brl(item.valorCentavos))
                            ]),
                            onTap: () => Navigator.pushNamed(
                                context, '/detalhes',
                                arguments: item)));
                  })));
}

class TransactionDetailsScreen extends StatelessWidget {
  final FinanceController controller;
  final Lancamento item;
  const TransactionDetailsScreen(
      {super.key, required this.controller, required this.item});
  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Detalhes do lançamento',
      controller: controller,
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(item.descricao, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ListTile(
            title: const Text('Valor'),
            subtitle: Text(brl(item.valorCentavos))),
        ListTile(title: const Text('Tipo'), subtitle: Text(item.tipo)),
        ListTile(
            title: const Text('Categoria'), subtitle: Text(item.categoriaId)),
        ListTile(
            title: const Text('Data'),
            subtitle: Text(item.data.toLocal().toString().split(' ').first)),
        ListTile(
            title: const Text('Sincronização'),
            subtitle: Text(item.sincronizado
                ? 'Enviado ao endpoint de demonstração'
                : 'Pendente de envio')),
        FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/editar', arguments: item),
            icon: const Icon(Icons.edit),
            label: const Text('Editar')),
      ]));
}
