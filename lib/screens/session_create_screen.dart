import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import 'session_active_screen.dart';

class SessionCreateScreen extends StatefulWidget {
  const SessionCreateScreen({super.key});

  @override
  State<SessionCreateScreen> createState() => _SessionCreateScreenState();
}

class _SessionCreateScreenState extends State<SessionCreateScreen> {
  final StorageService _storage = StorageService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _casinoController = TextEditingController();
  final TextEditingController _buyInController = TextEditingController();
  final TextEditingController _lossLimitController = TextEditingController();
  final TextEditingController _winTargetController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedGame = 'Blackjack';
  final List<String> _games = [
    'Blackjack',
    'Craps',
    'Roulette',
    'Baccarat',
    'Poker',
    'Slots',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final prefs = await _storage.getPreferences();
    if (prefs.defaultLossLimit != null) {
      _lossLimitController.text = prefs.defaultLossLimit.toString();
    }
    if (prefs.defaultWinTarget != null) {
      _winTargetController.text = prefs.defaultWinTarget.toString();
    }
  }

  @override
  void dispose() {
    _casinoController.dispose();
    _buyInController.dispose();
    _lossLimitController.dispose();
    _winTargetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;

    final buyIn = double.parse(_buyInController.text);
    final lossLimit = _lossLimitController.text.isNotEmpty
        ? double.tryParse(_lossLimitController.text)
        : null;
    final winTarget = _winTargetController.text.isNotEmpty
        ? double.tryParse(_winTargetController.text)
        : null;

    final session = Session(
      casino: _casinoController.text,
      game: _selectedGame,
      buyIn: buyIn,
      lossLimit: lossLimit,
      winTarget: winTarget,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    await _storage.saveSession(session);
    await _storage.setActiveSession(session.id);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SessionActiveScreen(session: session),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Session'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _casinoController,
              decoration: const InputDecoration(
                labelText: 'Casino Name',
                hintText: 'Enter casino name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter casino name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGame,
              decoration: const InputDecoration(
                labelText: 'Game',
              ),
              items: _games
                  .map((game) => DropdownMenuItem(
                        value: game,
                        child: Text(game),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedGame = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buyInController,
              decoration: const InputDecoration(
                labelText: 'Buy-in Amount',
                prefixText: '\$ ',
                hintText: 'Enter initial buy-in',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter buy-in amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Optional Limits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lossLimitController,
              decoration: const InputDecoration(
                labelText: 'Loss Limit (Optional)',
                prefixText: '\$ ',
                hintText: 'Maximum loss allowed',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _winTargetController,
              decoration: const InputDecoration(
                labelText: 'Win Target (Optional)',
                prefixText: '\$ ',
                hintText: 'Target profit',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add any notes about this session',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createSession,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Start Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
