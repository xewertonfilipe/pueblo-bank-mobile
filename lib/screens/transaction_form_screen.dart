import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/storage_service.dart';
import '../utils/brl_currency.dart';
import '../widgets/app_feedback.dart';

enum TransactionFormSource { newTransaction, summary, transactions }

enum TransactionFormResult { goToSummary }

class TransactionFormArguments {
  const TransactionFormArguments({
    required this.source,
    this.transaction,
  });

  final TransactionFormSource source;
  final TransactionModel? transaction;
}

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  TransactionModel? _existing;
  TransactionCategory _category = TransactionCategory.deposit;
  DateTime _date = DateTime.now();
  File? _receipt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _existing == null) _amountFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_existing != null) return;
    final argument = ModalRoute.of(context)?.settings.arguments;
    final transaction = argument is TransactionFormArguments
        ? argument.transaction
        : argument is TransactionModel
            ? argument
            : null;
    if (transaction != null) {
      _existing = transaction;
      _amount.text = formatBrlCurrency(transaction.amount);
      _description.text = transaction.description;
      _category = transaction.category;
      _date = transaction.date;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _amountFocusNode.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _receipt = File(file.path));
  }

  void _removeReceipt() {
    setState(() => _receipt = null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;
    setState(() => _saving = true);
    var didCompleteSave = false;
    try {
      final amount = parseBrlCurrency(_amount.text);
      if (amount == null || amount <= 0) return;
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
      if (_receipt != null && _category == TransactionCategory.deposit) {
        final upload = await StorageService().uploadReceipt(
            userId: userId, transactionId: transaction.id, file: _receipt!);
        transaction = transaction.copyWith(
            receiptUrl: upload.url, receiptPath: upload.path);
        newReceiptPath = upload.path;
      }
      if (!mounted) return;
      await context.read<TransactionProvider>().save(transaction);
      if (previousReceiptPath != null &&
          newReceiptPath != null &&
          previousReceiptPath != newReceiptPath) {
        await StorageService().deleteReceiptByPath(previousReceiptPath);
      }
      if (mounted) {
        final isDeposit = _category == TransactionCategory.deposit;
        final isNew = _existing == null;
        didCompleteSave = true;
        final message = isNew
            ? (isDeposit
                ? 'Depositado com sucesso!'
                : 'Saque realizado com sucesso!')
            : 'Transação editada com sucesso!';
        if (isNew) {
          setState(() {
            _saving = false;
            _amount.clear();
            _description.clear();
            _category = TransactionCategory.deposit;
            _date = DateTime.now();
            _receipt = null;
          });
          FocusScope.of(context).unfocus();
          await AppFeedback.showSuccess(context, message);
          final createAnother = await _confirmCreateAnother();
          if (mounted && createAnother) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _amountFocusNode.requestFocus();
            });
          } else if (mounted) {
            Navigator.pop(context, TransactionFormResult.goToSummary);
          }
        } else {
          setState(() => _saving = false);
          Navigator.pop(context, true);
        }
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Não foi possível salvar a transação.',
        );
      }
    } finally {
      if (mounted && !didCompleteSave) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmCreateAnother() async {
    final createAnother = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nova transação'),
        content: const Text('Deseja cadastrar outra transação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
    return createAnother == true;
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
              focusNode: _amountFocusNode,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [BrlCurrencyInputFormatter()],
              decoration:
                  const InputDecoration(labelText: 'Valor', prefixText: r'R$ '),
              validator: (value) {
                final amount = parseBrlCurrency(value);
                return amount == null || amount <= 0
                    ? 'Informe um valor positivo.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<TransactionCategory>(
              segments: const [
                ButtonSegment(
                  value: TransactionCategory.deposit,
                  icon: Icon(Icons.arrow_downward),
                  label: Text('Depósito'),
                ),
                ButtonSegment(
                  value: TransactionCategory.withdrawal,
                  icon: Icon(Icons.arrow_upward),
                  label: Text('Saque'),
                ),
              ],
              selected: {_category},
              onSelectionChanged: (selection) {
                final value = selection.first;
                setState(() {
                  _category = value;
                  if (value == TransactionCategory.withdrawal) {
                    _receipt = null;
                  }
                });
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
                tooltip: 'Selecionar data',
              ),
            ),
            if (_category == TransactionCategory.deposit)
              OutlinedButton.icon(
                onPressed: _pickReceipt,
                icon: const Icon(Icons.attach_file),
                label: Text(
                    _receipt == null ? 'Anexar recibo' : 'Recibo selecionado'),
              ),
            if (_receipt != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _receipt!,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickReceipt,
                    icon: const Icon(Icons.edit),
                    label: const Text('Trocar'),
                  ),
                  TextButton.icon(
                    onPressed: _removeReceipt,
                    icon: const Icon(Icons.close),
                    label: const Text('Remover'),
                  ),
                ],
              ),
            ],
            if (_existing?.receiptUrl != null && _receipt == null) ...[
              const SizedBox(height: 8),
              Text('Comprovante anexado',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _existing!.receiptUrl!,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) =>
                      const Text('Não foi possível carregar o comprovante.'),
                ),
              ),
            ],
            if (_existing != null &&
                _category == TransactionCategory.deposit &&
                _existing?.receiptUrl == null &&
                _receipt == null) ...[
              const SizedBox(height: 8),
              Text(
                'Nenhum comprovante anexado.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
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
                  : Text(
                      _existing == null
                          ? _category == TransactionCategory.deposit
                              ? 'Salvar depósito'
                              : 'Salvar saque'
                          : 'Salvar alterações',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
