import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../theme/app_theme.dart';
import '../models/preferences.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  Preferences? _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _storage.getPreferences();
    setState(() {
      _prefs = prefs;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences(Preferences prefs) async {
    await _storage.savePreferences(prefs);
    setState(() {
      _prefs = prefs;
    });
  }

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('In-app review not available on this device'),
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  void _shareApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Casino Companion'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Casino Companion: Total Manager',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Track your casino sessions with ease! Fast calculators for payouts, chips, and tips. Educational tool for learning casino math.',
            ),
            SizedBox(height: 16),
            Text(
              '✓ Session tracking\n✓ Payout calculator\n✓ Chip counter\n✓ Tip calculator\n✓ Statistics & ROI',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(
                  text: 'Casino Companion: Total Manager - Track casino sessions, calculate payouts, count chips, and more! Educational tool for learning casino math.',
                ),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share message copied to clipboard!'),
                ),
              );
            },
            child: const Text('Copy Message'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all sessions, calculations, and reset settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _prefs == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection('General'),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            subtitle: Text(_prefs!.currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(),
          ),
          const Divider(),
          _buildSection('Chip Denominations'),
          ListTile(
            leading: const Icon(Icons.casino),
            title: const Text('Edit Chip Denoms'),
            subtitle: Text('${_prefs!.chipDenoms.length} denominations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChipDenomsEditor(),
          ),
          const Divider(),
          _buildSection('Session Defaults'),
          ListTile(
            leading: const Icon(Icons.trending_down),
            title: const Text('Default Loss Limit'),
            subtitle: Text(_prefs!.defaultLossLimit != null
                ? '\$${_prefs!.defaultLossLimit!.toStringAsFixed(2)}'
                : 'Not set'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDefaultLimitEditor('loss'),
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text('Default Win Target'),
            subtitle: Text(_prefs!.defaultWinTarget != null
                ? '\$${_prefs!.defaultWinTarget!.toStringAsFixed(2)}'
                : 'Not set'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDefaultLimitEditor('win'),
          ),
          const Divider(),
          _buildSection('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share this app'),
            subtitle: const Text('Tell others about Casino Companion'),
            onTap: () => _shareApp(),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate this app'),
            subtitle: const Text('Leave a review on the store'),
            onTap: () => _rateApp(),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () => _launchURL('https://flutter.dev/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Use'),
            onTap: () => _launchURL('https://flutter.dev/terms'),
          ),
          const Divider(),
          _buildSection('Data'),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all sessions and settings'),
            textColor: AppColors.negative,
            iconColor: AppColors.negative,
            onTap: _clearData,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Utility tool. No gambling or wagers. Not affiliated with casinos.\nEducational use only.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accentBlue,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showCurrencyPicker() {
    final currencies = ['USD', 'EUR', 'GBP', 'PLN', 'CAD', 'AUD'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            return ListTile(
              title: Text(currency),
              leading: Radio<String>(
                value: currency,
                groupValue: _prefs!.currency,
                onChanged: (value) {
                  if (value != null) {
                    _savePreferences(_prefs!.copyWith(currency: value));
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                _savePreferences(_prefs!.copyWith(currency: currency));
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showChipDenomsEditor() {
    showDialog(
      context: context,
      builder: (context) => _ChipDenomsEditorDialog(
        denoms: _prefs!.chipDenoms,
        onSave: (newDenoms) {
          _savePreferences(_prefs!.copyWith(chipDenoms: newDenoms));
        },
      ),
    );
  }

  void _showDefaultLimitEditor(String type) {
    final isLoss = type == 'loss';
    final currentValue = isLoss ? _prefs!.defaultLossLimit : _prefs!.defaultWinTarget;
    final controller = TextEditingController(
      text: currentValue?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Default ${isLoss ? "Loss Limit" : "Win Target"}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: isLoss ? 'Loss Limit' : 'Win Target',
            prefixText: '\$ ',
            hintText: 'Leave empty to disable',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (currentValue != null)
            TextButton(
              onPressed: () {
                if (isLoss) {
                  _savePreferences(_prefs!.copyWith(defaultLossLimit: null));
                } else {
                  _savePreferences(_prefs!.copyWith(defaultWinTarget: null));
                }
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                if (isLoss) {
                  _savePreferences(_prefs!.copyWith(defaultLossLimit: value));
                } else {
                  _savePreferences(_prefs!.copyWith(defaultWinTarget: value));
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ChipDenomsEditorDialog extends StatefulWidget {
  final List<double> denoms;
  final Function(List<double>) onSave;

  const _ChipDenomsEditorDialog({
    required this.denoms,
    required this.onSave,
  });

  @override
  State<_ChipDenomsEditorDialog> createState() => _ChipDenomsEditorDialogState();
}

class _ChipDenomsEditorDialogState extends State<_ChipDenomsEditorDialog> {
  late List<double> _denoms;
  final TextEditingController _newDenomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _denoms = List.from(widget.denoms);
  }

  @override
  void dispose() {
    _newDenomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Chip Denominations'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newDenomController,
                    decoration: const InputDecoration(
                      labelText: 'Add denomination',
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final value = double.tryParse(_newDenomController.text);
                    if (value != null && value > 0 && !_denoms.contains(value)) {
                      setState(() {
                        _denoms.add(value);
                        _denoms.sort();
                        _newDenomController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _denoms.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.casino),
                    title: Text('\$${_denoms[index].toStringAsFixed(0)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _denoms.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
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
            widget.onSave(_denoms);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
