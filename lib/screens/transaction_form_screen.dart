import 'package:flutter/material.dart';
import '../controllers/finance_controller.dart';
import '../models/finance_models.dart';
import '../widgets/app_shell.dart';

class TransactionFormScreen extends StatefulWidget {
  final FinanceController controller;
  final Lancamento? item;
  const TransactionFormScreen({super.key, required this.controller, this.item});
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController descricao;
  late final TextEditingController valor;
  late String tipo;
  late String categoriaId;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    descricao = TextEditingController(text: widget.item?.descricao ?? '');
    valor = TextEditingController(
        text: widget.item == null
            ? ''
            : (widget.item!.valorCentavos / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ','));
    tipo = widget.item?.tipo ?? 'despesa';
    categoriaId = widget.item?.categoriaId ?? 'geral';
  }

  @override
  void dispose() {
    descricao.dispose();
    valor.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!form.currentState!.validate()) return;
    setState(() => salvando = true);
    try {
      final item = Lancamento(
          id: widget.item?.id ?? newId(),
          descricao: descricao.text.trim(),
          valorCentavos: parseCentavos(valor.text),
          tipo: tipo,
          categoriaId: categoriaId,
          data: widget.item?.data ?? DateTime.now());
      await widget.controller.salvarLancamento(item);
      if (!mounted) return;
      alertar(context, 'Salvo no dispositivo. Envie na tela de sincronização.');
      Navigator.pushNamedAndRemoveUntil(
          context, '/lancamentos', (r) => r.isFirst);
    } catch (e) {
      if (mounted) alertar(context, 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.controller.categorias;
    final selected = categories.any((c) => c.id == categoriaId)
        ? categoriaId
        : (categories.isNotEmpty ? categories.first.id : null);
    return AppShell(
        title: widget.item == null ? 'Novo lançamento' : 'Editar lançamento',
        controller: widget.controller,
        body: Form(
            key: form,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              TextFormField(
                  controller: descricao,
                  decoration: const InputDecoration(
                      labelText: 'Descrição', border: OutlineInputBorder()),
                  validator: (text) => (text == null || text.trim().isEmpty)
                      ? 'Descrição obrigatória'
                      : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: valor,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Valor (R\$)', border: OutlineInputBorder()),
                  validator: (text) {
                    try {
                      parseCentavos(text ?? '');
                      return null;
                    } catch (_) {
                      return 'Informe um valor positivo';
                    }
                  }),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(
                      labelText: 'Tipo', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'receita', child: Text('Receita')),
                    DropdownMenuItem(value: 'despesa', child: Text('Despesa'))
                  ],
                  onChanged: (value) => setState(() => tipo = value ?? tipo)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                      labelText: 'Categoria', border: OutlineInputBorder()),
                  items: categories
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nome)))
                      .toList(),
                  validator: (v) => v == null ? 'Cadastre uma categoria' : null,
                  onChanged: (v) =>
                      setState(() => categoriaId = v ?? categoriaId)),
              const SizedBox(height: 20),
              FilledButton.icon(
                  onPressed: salvando ? null : salvar,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar lançamento')),
            ])));
  }
}
