import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/session.dart';
import '../services/storage_service.dart';

class SessionActiveScreen extends StatefulWidget {
  final Session session;

  const SessionActiveScreen({super.key, required this.session});

  @override
  State<SessionActiveScreen> createState() => _SessionActiveScreenState();
}

class _SessionActiveScreenState extends State<SessionActiveScreen> {
  final StorageService _storage = StorageService();
  late Session _session;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = DateTime.now().difference(_session.startedAt);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _addBuyIn() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BuyInDialog(),
    );

    if (result != null) {
      final event = SessionEvent(
        type: SessionEventType.buyin,
        amount: result['amount'] as double,
        text: result['note'] as String?,
      );

      setState(() {
        _session.events.add(event);
      });

      await _storage.saveSession(_session);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Buy-in of \$${result['amount']} added')),
        );
      }
    }
  }

  Future<void> _addNote() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AddNoteDialog(),
    );

    if (result != null && result.isNotEmpty) {
      final event = SessionEvent(
        type: SessionEventType.note,
        text: result,
      );

      setState(() {
        _session.events.add(event);
      });

      await _storage.saveSession(_session);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added')),
        );
      }
    }
  }

  Future<void> _closeSession() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CloseSessionDialog(session: _session),
    );

    if (result != null) {
      setState(() {
        _session.cashOut = result['cashOut'] as double;
        _session.endedAt = DateTime.now();
        
        if (result['note'] != null && (result['note'] as String).isNotEmpty) {
          _session.events.add(SessionEvent(
            type: SessionEventType.note,
            text: result['note'] as String,
          ));
        }

        _session.events.add(SessionEvent(
          type: SessionEventType.cashout,
          amount: _session.cashOut,
          text: 'Session closed',
        ));
      });

      await _storage.saveSession(_session);
      await _storage.setActiveSession(null);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_session.casino} • ${_session.game}'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Time',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _formatDuration(_elapsed),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: 22,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Balance',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '\$${_session.currentBalance.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: _session.currentBalance >= _session.buyIn
                                      ? AppColors.positive
                                      : AppColors.negative,
                                  fontSize: 22,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addBuyIn,
                        icon: const Icon(Icons.add),
                        label: const Text('Buy-in'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addNote,
                        icon: const Icon(Icons.note_add),
                        label: const Text('Note'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _closeSession,
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.negative,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _session.events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add buy-ins or notes as you play',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _session.events.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final event = _session.events[_session.events.length - 1 - index];
                      return _buildEventItem(event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(SessionEvent event) {
    IconData icon;
    Color iconColor;
    String title;

    switch (event.type) {
      case SessionEventType.buyin:
        icon = Icons.add_circle;
        iconColor = AppColors.accentBlue;
        title = 'Buy-in: \$${event.amount!.toStringAsFixed(2)}';
        break;
      case SessionEventType.note:
        icon = Icons.note;
        iconColor = AppColors.muted;
        title = 'Note';
        break;
      case SessionEventType.cashout:
        icon = Icons.logout;
        iconColor = AppColors.negative;
        title = 'Cash-out: \$${event.amount!.toStringAsFixed(2)}';
        break;
      case SessionEventType.calcSaved:
        icon = Icons.calculate;
        iconColor = AppColors.positive;
        title = 'Calculation Saved';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: event.text != null
            ? Text(
                event.text!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: SizedBox(
          width: 50,
          child: Text(
            DateFormat('HH:mm').format(event.ts),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _BuyInDialog extends StatefulWidget {
  @override
  State<_BuyInDialog> createState() => _BuyInDialogState();
}

class _BuyInDialogState extends State<_BuyInDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('+ Buy-in'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount != null && amount > 0) {
              Navigator.pop(context, {
                'amount': amount,
                'note': _noteController.text.isEmpty ? null : _noteController.text,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final TextEditingController _noteController = TextEditingController();
  final List<String> _presets = ['table change', 'break', 'dealer tip'];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            children: _presets
                .map((preset) => ActionChip(
                      label: Text(preset),
                      onPressed: () {
                        _noteController.text = preset;
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Enter note text',
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_noteController.text.isNotEmpty) {
              Navigator.pop(context, _noteController.text);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CloseSessionDialog extends StatefulWidget {
  final Session session;

  const _CloseSessionDialog({required this.session});

  @override
  State<_CloseSessionDialog> createState() => _CloseSessionDialogState();
}

class _CloseSessionDialogState extends State<_CloseSessionDialog> {
  final TextEditingController _cashOutController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  double? _cashOut;
  double? _winLoss;
  double? _roi;

  @override
  void dispose() {
    _cashOutController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final cashOut = double.tryParse(_cashOutController.text);
    if (cashOut != null && cashOut >= 0) {
      setState(() {
        _cashOut = cashOut;
        _winLoss = cashOut - widget.session.totalBuyIn;
        _roi = widget.session.totalBuyIn > 0
            ? (_winLoss! / widget.session.totalBuyIn) * 100
            : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close Session'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _cashOutController,
              decoration: const InputDecoration(
                labelText: 'Cash-out Amount',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
              maxLines: 2,
            ),
            if (_winLoss != null && _roi != null) ...[
              const SizedBox(height: 24),
              Card(
                color: AppColors.surfaceAlt,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        context,
                        'Total Buy-in',
                        '\$${widget.session.totalBuyIn.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        'Cash-out',
                        '\$${_cashOut!.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        'Win/Loss',
                        '\$${_winLoss!.toStringAsFixed(2)}',
                        valueColor: _winLoss! >= 0
                            ? AppColors.positive
                            : AppColors.negative,
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        'ROI',
                        '${_roi!.toStringAsFixed(2)}%',
                        valueColor: _roi! >= 0
                            ? AppColors.positive
                            : AppColors.negative,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_cashOut != null) {
              Navigator.pop(context, {
                'cashOut': _cashOut,
                'note': _noteController.text.isEmpty ? null : _noteController.text,
              });
            }
          },
          child: const Text('Close Session'),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
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
