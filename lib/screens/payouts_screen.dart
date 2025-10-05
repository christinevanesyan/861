import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../data/odds_data.dart';
import '../models/calculators.dart';
import '../services/storage_service.dart';

class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedGame;
  String? _selectedBetType;
  double? _amount;
  BetInfo? _betInfo;
  double? _payout;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_selectedGame == null || _selectedBetType == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final info = OddsData.getBetInfo(_selectedGame!, _selectedBetType!);
    if (info == null) return;

    setState(() {
      _amount = amount;
      _betInfo = info;
      _payout = OddsData.calculatePayout(info.odds, amount);
    });
  }

  void _reset() {
    setState(() {
      _selectedGame = null;
      _selectedBetType = null;
      _amount = null;
      _betInfo = null;
      _payout = null;
      _amountController.clear();
    });
  }

  Future<void> _saveAsNote() async {
    if (_selectedGame == null ||
        _selectedBetType == null ||
        _amount == null ||
        _betInfo == null ||
        _payout == null) {
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SaveNoteDialog(),
    );

    if (result != null) {
      final saved = PayoutSaved(
        game: _selectedGame!,
        betType: _selectedBetType!,
        amount: _amount!,
        odds: _betInfo!.odds,
        payout: _payout!,
        houseEdgePct: _betInfo!.houseEdgePct,
        note: result.isEmpty ? null : result,
      );

      await _storage.savePayout(saved);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout saved')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payouts'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedGame,
              decoration: const InputDecoration(
                labelText: 'Game',
              ),
              items: OddsData.games
                  .map((game) => DropdownMenuItem(
                        value: game,
                        child: Text(game),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGame = value;
                  _selectedBetType = null;
                  _betInfo = null;
                  _payout = null;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedGame != null)
              DropdownButtonFormField<String>(
                value: _selectedBetType,
                decoration: const InputDecoration(
                  labelText: 'Bet Type',
                ),
                items: OddsData.getBetTypes(_selectedGame!)
                    .map((betType) => DropdownMenuItem(
                          value: betType,
                          child: Text(betType),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBetType = value;
                    _calculate();
                  });
                },
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 24),
            if (_betInfo != null && _payout != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Result',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      _buildResultRow('Odds', _betInfo!.odds),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Payout',
                        '\$${_payout!.toStringAsFixed(2)}',
                        valueColor: AppColors.positive,
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'House Edge',
                        '${_betInfo!.houseEdgePct.toStringAsFixed(2)}%',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.accentBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _betInfo!.tip,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
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
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAsNote,
                      child: const Text('Save Note'),
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

  Widget _buildResultRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
