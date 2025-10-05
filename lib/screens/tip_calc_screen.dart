import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/calculators.dart';
import '../services/storage_service.dart';

class TipCalcScreen extends StatefulWidget {
  const TipCalcScreen({super.key});

  @override
  State<TipCalcScreen> createState() => _TipCalcScreenState();
}

class _TipCalcScreenState extends State<TipCalcScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _baseController = TextEditingController();
  final TextEditingController _tipValueController = TextEditingController();
  final TextEditingController _splitController = TextEditingController(text: '1');

  String _mode = 'percent'; // 'percent' or 'fixed'
  double? _base;
  double? _tipValue;
  int _split = 1;
  double? _tipTotal;
  double? _perPerson;

  @override
  void dispose() {
    _baseController.dispose();
    _tipValueController.dispose();
    _splitController.dispose();
    super.dispose();
  }

  void _calculate() {
    final base = double.tryParse(_baseController.text);
    final tipValue = double.tryParse(_tipValueController.text);
    final split = int.tryParse(_splitController.text);

    if (base == null || base <= 0 || tipValue == null || tipValue <= 0) {
      setState(() {
        _base = null;
        _tipTotal = null;
        _perPerson = null;
      });
      return;
    }

    final splitCount = split != null && split > 0 ? split : 1;

    setState(() {
      _base = base;
      _tipValue = tipValue;
      _split = splitCount;

      if (_mode == 'percent') {
        _tipTotal = base * (tipValue / 100);
      } else {
        _tipTotal = tipValue;
      }

      _perPerson = (base + _tipTotal!) / splitCount;
    });
  }

  Future<void> _copyToClipboard() async {
    if (_tipTotal == null || _perPerson == null) return;

    final text = 'Base: \$${_base!.toStringAsFixed(2)}\n'
        'Tip: \$${_tipTotal!.toStringAsFixed(2)}\n'
        'Total: \$${(_base! + _tipTotal!).toStringAsFixed(2)}\n'
        'Per Person: \$${_perPerson!.toStringAsFixed(2)}';

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  Future<void> _saveAsNote() async {
    if (_base == null || _tipValue == null || _tipTotal == null || _perPerson == null) {
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SaveNoteDialog(),
    );

    if (result != null) {
      final saved = TipCalcSaved(
        base: _base!,
        mode: _mode,
        tipValue: _tipValue!,
        split: _split,
        tipTotal: _tipTotal!,
        perPerson: _perPerson!,
        note: result.isEmpty ? null : result,
      );

      await _storage.saveTipCalc(saved);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip calculation saved')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tip Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _baseController,
              decoration: const InputDecoration(
                labelText: 'Base Amount',
                prefixText: '\$ ',
                hintText: 'Enter winnings or check amount',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tip Mode',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Percent'),
                            selected: _mode == 'percent',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _mode = 'percent';
                                  _tipValueController.clear();
                                  _calculate();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Fixed'),
                            selected: _mode == 'fixed',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _mode = 'fixed';
                                  _tipValueController.clear();
                                  _calculate();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tipValueController,
              decoration: InputDecoration(
                labelText: _mode == 'percent' ? 'Tip Percentage' : 'Fixed Tip Amount',
                suffixText: _mode == 'percent' ? '%' : null,
                prefixText: _mode == 'fixed' ? '\$ ' : null,
                hintText: _mode == 'percent' ? 'e.g., 15' : 'e.g., 10.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _splitController,
              decoration: const InputDecoration(
                labelText: 'Split (Number of people)',
                hintText: 'Enter number of people',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 24),
            if (_tipTotal != null && _perPerson != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      _buildResultRow('Base Amount', '\$${_base!.toStringAsFixed(2)}'),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Tip Amount',
                        '\$${_tipTotal!.toStringAsFixed(2)}',
                        valueColor: AppColors.accentBlue,
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Total',
                        '\$${(_base! + _tipTotal!).toStringAsFixed(2)}',
                        valueColor: AppColors.positive,
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 24),
                      _buildResultRow(
                        'Per Person (${_split} ${_split == 1 ? "person" : "people"})',
                        '\$${_perPerson!.toStringAsFixed(2)}',
                        labelStyle: Theme.of(context).textTheme.titleLarge,
                        valueStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.accentBlue,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveAsNote,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value, {
    Color? valueColor,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle ?? Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: valueStyle ??
                Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: valueColor,
                    ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SaveNoteDialog extends StatefulWidget {
  @override
  State<_SaveNoteDialog> createState() => _SaveNoteDialogState();
}

class _SaveNoteDialogState extends State<_SaveNoteDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Note'),
      content: TextField(
        controller: _noteController,
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          hintText: 'Add a note...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _noteController.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
