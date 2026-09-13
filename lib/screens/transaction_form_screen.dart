import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/storage_service.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  TransactionModel? _existing;
  TransactionCategory _category = TransactionCategory.deposit;
  DateTime _date = DateTime.now();
  File? _receipt;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_existing != null) return;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is TransactionModel) {
      _existing = argument;
      _amount.text = argument.amount.toStringAsFixed(2);
      _description.text = argument.description;
      _category = argument.category;
      _date = argument.date;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _receipt = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;
    setState(() => _saving = true);
    try {
      final amount = double.parse(_amount.text.replaceAll(',', '.'));
      var transaction = TransactionModel(id: _existing?.id ?? '', amount: amount, category: _category, date: _date, description: _description.text.trim(), receiptUrl: _existing?.receiptUrl, createdAt: _existing?.createdAt);
      if (_receipt != null) {
        final id = transaction.id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : transaction.id;
        final url = await StorageService().uploadReceipt(userId: userId, transactionId: id, file: _receipt!);
        transaction = transaction.copyWith(id: id, receiptUrl: url);
      }
      if (!mounted) return;
      await context.read<TransactionProvider>().save(transaction);
      if (mounted) {
        final message = _existing == null
            ? (_category == TransactionCategory.deposit
                ? 'Depositado com sucesso!'
                : 'Saque realizado com sucesso!')
            : 'Transação editada com sucesso!';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nao foi possivel salvar a transacao.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Nova transacao' : 'Editar transacao'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(labelText: 'Valor', prefixText: r'R$ '),
              validator: (value) {
                final amount = double.tryParse((value ?? '').replaceAll(',', '.'));
                return amount == null || amount <= 0 ? 'Informe um valor positivo.' : null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransactionCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: const [
                DropdownMenuItem(
                  value: TransactionCategory.deposit,
                  child: Text('Deposito'),
                ),
                DropdownMenuItem(
                  value: TransactionCategory.withdrawal,
                  child: Text('Saque'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descricao'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Data: ${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
              ),
              trailing: IconButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: _date,
                  );
                  if (date != null) setState(() => _date = date);
                },
                icon: const Icon(Icons.calendar_month),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickReceipt,
              icon: const Icon(Icons.attach_file),
              label: Text(_receipt == null ? 'Anexar recibo' : 'Recibo selecionado'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
