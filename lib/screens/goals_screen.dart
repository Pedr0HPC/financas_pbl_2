import 'package:flutter/material.dart';
import '../controllers/finance_controller.dart';
import '../models/finance_models.dart';
import '../widgets/app_shell.dart';

class GoalsScreen extends StatelessWidget {
  final FinanceController controller;
  const GoalsScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Metas financeiras',
      controller: controller,
      floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/nova-meta'),
          child: const Icon(Icons.add)),
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => controller.metas.isEmpty
              ? const Center(child: Text('Nenhuma meta cadastrada.'))
              : ListView.builder(
                  itemCount: controller.metas.length,
                  itemBuilder: (context, i) {
                    final m = controller.metas[i];
                    return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                            title: Text(m.nome),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${brl(m.acumuladoCentavos)} de ${brl(m.alvoCentavos)}'),
                                  LinearProgressIndicator(value: m.progresso),
                                  Text(
                                      'Prazo: ${m.prazo.day}/${m.prazo.month}/${m.prazo.year}'),
                                ]),
                            trailing: const Icon(Icons.edit),
                            onTap: () => Navigator.pushNamed(
                                context, '/nova-meta',
                                arguments: m)));
                  })));
}

class GoalFormScreen extends StatefulWidget {
  final FinanceController controller;
  final MetaFinanceira? meta;
  const GoalFormScreen({super.key, required this.controller, this.meta});
  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController nome;
  late final TextEditingController alvo;
  late final TextEditingController atual;
  late DateTime prazo;
  @override
  void initState() {
    super.initState();
    final meta = widget.meta;
    nome = TextEditingController(text: meta?.nome ?? '');
    alvo = TextEditingController(
        text: meta == null ? '' : (meta.alvoCentavos / 100).toStringAsFixed(2));
    atual = TextEditingController(
        text: meta == null
            ? '0'
            : (meta.acumuladoCentavos / 100).toStringAsFixed(2));
    prazo = meta?.prazo ?? DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    nome.dispose();
    alvo.dispose();
    atual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
      title: 'Cadastrar / editar meta',
      controller: widget.controller,
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome da meta'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nome obrigatório' : null),
            TextFormField(
                controller: alvo,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Valor-alvo (R\$)'),
                validator: (v) {
                  try {
                    parseCentavos(v ?? '');
                    return null;
                  } catch (_) {
                    return 'Alvo inválido';
                  }
                }),
            TextFormField(
                controller: atual,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Valor já acumulado (R\$)'),
                validator: (v) {
                  final parsed =
                      double.tryParse((v ?? '').replaceAll(',', '.'));
                  return parsed == null || parsed < 0 ? 'Valor inválido' : null;
                }),
            const SizedBox(height: 12),
            ListTile(
                title: const Text('Prazo'),
                subtitle: Text('${prazo.day}/${prazo.month}/${prazo.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final resultado = await showDatePicker(
                      context: context,
                      initialDate: prazo.isBefore(DateTime.now())
                          ? DateTime.now()
                          : prazo,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100));
                  if (resultado != null) setState(() => prazo = resultado);
                }),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  try {
                    final valor = double.parse(atual.text.replaceAll(',', '.'));
                    await widget.controller.salvarMeta(MetaFinanceira(
                        id: widget.meta?.id ?? newId(),
                        nome: nome.text.trim(),
                        alvoCentavos: parseCentavos(alvo.text),
                        acumuladoCentavos: (valor * 100).round(),
                        prazo: prazo));
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/metas', (r) => r.isFirst);
                    }
                  } catch (e) {
                    if (context.mounted) alertar(context, '$e');
                  }
                },
                child: const Text('Salvar meta')),
            if (widget.meta != null)
              TextButton(
                  onPressed: () async {
                    await widget.controller.excluirMeta(widget.meta!.id);
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/metas', (r) => r.isFirst);
                    }
                  },
                  child: const Text('Excluir meta')),
          ])));
}
