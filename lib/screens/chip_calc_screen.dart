import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/session.dart';
import '../models/calculators.dart';
import '../services/storage_service.dart';
import '../models/preferences.dart';

class ChipCalcScreen extends StatefulWidget {
  final Session? activeSession;

  const ChipCalcScreen({super.key, this.activeSession});

  @override
  State<ChipCalcScreen> createState() => _ChipCalcScreenState();
}

class _ChipCalcScreenState extends State<ChipCalcScreen> {
  final StorageService _storage = StorageService();
  final Map<double, int> _chipCounts = {};
  List<double> _denoms = [];

  @override
  void initState() {
    super.initState();
    _loadDenoms();
  }

  Future<void> _loadDenoms() async {
    final prefs = await _storage.getPreferences();
    setState(() {
      _denoms = prefs.chipDenoms;
      for (var denom in _denoms) {
        _chipCounts[denom] = 0;
      }
    });
  }

  double get _total {
    double total = 0;
    _chipCounts.forEach((denom, count) {
      total += denom * count;
    });
    return total;
  }

  void _updateCount(double denom, int change) {
    setState(() {
      final current = _chipCounts[denom] ?? 0;
      final newCount = current + change;
      _chipCounts[denom] = newCount < 0 ? 0 : newCount;
    });
  }

  void _clear() {
    setState(() {
      _chipCounts.updateAll((key, value) => 0);
    });
  }

  Future<void> _save() async {
    if (_total == 0) return;

    final denoms = _chipCounts.entries
        .where((e) => e.value > 0)
        .map((e) => ChipDenom(value: e.key, count: e.value))
        .toList();

    if (widget.activeSession != null) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save Chip Count'),
          content: const Text('Save to current session or global list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'global'),
              child: const Text('Global'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'session'),
              child: const Text('Session'),
            ),
          ],
        ),
      );

      if (choice == null) return;

      final saved = ChipCalcSaved(
        denoms: denoms,
        total: _total,
        scope: choice,
        sessionId: choice == 'session' ? widget.activeSession!.id : null,
      );

      await _storage.saveChipCalc(saved);

      if (choice == 'session') {
        // Add to session events
        final session = widget.activeSession!;
        session.events.add(SessionEvent(
          type: SessionEventType.calcSaved,
          text: 'Chip count: \$${_total.toStringAsFixed(2)}',
          calcRef: CalcRef(kind: 'chip', id: saved.id),
        ));
        await _storage.saveSession(session);
      }
    } else {
      final saved = ChipCalcSaved(
        denoms: denoms,
        total: _total,
        scope: 'global',
      );
      await _storage.saveChipCalc(saved);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chip count saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chip Calculator'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _denoms.length,
              itemBuilder: (context, index) {
                final denom = _denoms[index];
                final count = _chipCounts[denom] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getChipColor(denom),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: FittedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      '\$${denom.toInt()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${denom.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontSize: 18,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Total: \$${(denom * count).toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontSize: 12,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$count',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactButton('-10', () => _updateCount(denom, -10), false),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildCompactButton('-5', () => _updateCount(denom, -5), false),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildCompactButton('-1', () => _updateCount(denom, -1), false),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCompactButton('+1', () => _updateCount(denom, 1), true),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildCompactButton('+5', () => _updateCount(denom, 5), true),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildCompactButton('+10', () => _updateCount(denom, 10), true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.accentBlue,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clear,
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _total > 0 ? _save : null,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton(String label, VoidCallback onPressed, bool isPositive) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPositive ? AppColors.accentBlue : AppColors.surfaceAlt,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: FittedBox(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getChipColor(double denom) {
    if (denom >= 1000) return const Color(0xFF8B5CF6); // Purple
    if (denom >= 500) return const Color(0xFFEC4899); // Pink
    if (denom >= 100) return const Color(0xFF000000); // Black
    if (denom >= 25) return const Color(0xFF22C55E); // Green
    if (denom >= 5) return const Color(0xFFEF4444); // Red
    return const Color(0xFF3B82F6); // Blue
  }
}
