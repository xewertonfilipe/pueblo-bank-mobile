import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_flushbar/flushbar.dart';
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
      final previousReceiptPath = _existing?.receiptPath;
      String? newReceiptPath;
      var transaction = TransactionModel(
        id: _existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        amount: amount,
        category: _category,
        date: _date,
        description: _description.text.trim(),
        receiptUrl: _existing?.receiptUrl,
        receiptPath: _existing?.receiptPath,
        createdAt: _existing?.createdAt,
      );
      if (_receipt != null) {
        final upload = await StorageService().uploadReceipt(userId: userId, transactionId: transaction.id, file: _receipt!);
        transaction = transaction.copyWith(receiptUrl: upload.url, receiptPath: upload.path);
        newReceiptPath = upload.path;
      }
      if (!mounted) return;
      await context.read<TransactionProvider>().save(transaction);
      if (previousReceiptPath != null && newReceiptPath != null && previousReceiptPath != newReceiptPath) {
        await StorageService().deleteReceiptByPath(previousReceiptPath);
      }
      if (mounted) {
        final isDeposit = _category == TransactionCategory.deposit;
        final isNew = _existing == null;
        final message = isNew
            ? (isDeposit ? 'Depositado com sucesso!' : 'Saque realizado com sucesso!')
            : 'Transação editada com sucesso!';
        final backgroundColor = isNew
            ? (isDeposit ? Colors.green : Colors.red)
            : Colors.blue;
        Flushbar(
          message: message,
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
        ).show(context);
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar a transação.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Nova transação' : 'Editar transação'),
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
                  child: Text('Depósito'),
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
              decoration: const InputDecoration(labelText: 'Descrição'),
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
            if (_existing?.receiptUrl != null) ...[
              const SizedBox(height: 8),
              Text('Comprovante anexado', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _existing!.receiptUrl!,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) => const Text('Não foi possível carregar o comprovante.'),
                ),
              ),
            ],
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
