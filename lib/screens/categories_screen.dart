import 'package:flutter/material.dart';
import '../controllers/finance_controller.dart';
import '../models/finance_models.dart';
import '../widgets/app_shell.dart';

class CategoriesScreen extends StatelessWidget {
  final FinanceController controller;
  const CategoriesScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Categorias',
      controller: controller,
      floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/nova-categoria'),
          child: const Icon(Icons.add)),
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => ListView.builder(
              itemCount: controller.categorias.length,
              itemBuilder: (context, index) {
                final c = controller.categorias[index];
                return ListTile(
                    title: Text(c.nome),
                    subtitle: Text(c.limiteCentavos == 0
                        ? 'Sem limite orçamentário'
                        : 'Limite: ${brl(c.limiteCentavos)}'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => Navigator.pushNamed(context, '/nova-categoria',
                        arguments: c));
              })));
}

class CategoryFormScreen extends StatefulWidget {
  final FinanceController controller;
  final Categoria? categoria;
  const CategoryFormScreen(
      {super.key, required this.controller, this.categoria});
  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController nome;
  late final TextEditingController limite;
  @override
  void initState() {
    super.initState();
    nome = TextEditingController(text: widget.categoria?.nome ?? '');
    limite = TextEditingController(
        text: widget.categoria == null || widget.categoria!.limiteCentavos == 0
            ? ''
            : (widget.categoria!.limiteCentavos / 100).toStringAsFixed(2));
  }

  @override
  void dispose() {
    nome.dispose();
    limite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Categoria / orçamento',
      controller: widget.controller,
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
                controller: nome,
                decoration:
                    const InputDecoration(labelText: 'Nome da categoria'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome'
                    : null),
            TextFormField(
                controller: limite,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Limite de gastos (opcional)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  try {
                    parseCentavos(value);
                    return null;
                  } catch (_) {
                    return 'Informe um limite positivo';
                  }
                }),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  try {
                    await widget.controller.salvarCategoria(Categoria(
                        id: widget.categoria?.id ?? newId(),
                        nome: nome.text.trim(),
                        limiteCentavos: limite.text.trim().isEmpty
                            ? 0
                            : parseCentavos(limite.text)));
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/categorias', (r) => r.isFirst);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      alertar(context, 'Não foi possível salvar: $e');
                    }
                  }
                },
                child: const Text('Salvar categoria')),
            if (widget.categoria != null &&
                !['geral', 'salario'].contains(widget.categoria!.id))
              TextButton(
                  onPressed: () async {
                    try {
                      await widget.controller
                          .excluirCategoria(widget.categoria!.id);
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/categorias', (r) => r.isFirst);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        alertar(context,
                            'Categoria com lançamentos vinculados não pode ser removida. $e');
                      }
                    }
                  },
                  child: const Text('Excluir categoria')),
          ])));
}
