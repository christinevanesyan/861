import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/session.dart';
import 'payouts_screen.dart';
import 'chip_calc_screen.dart';
import 'tip_calc_screen.dart';
import 'session_create_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<Session> _sessions = [];
  Session? _activeSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _storage.getSessions();
    final activeSession = await _storage.getActiveSession();
    
    setState(() {
      _sessions = sessions;
      _activeSession = activeSession;
      _isLoading = false;
    });
  }

  bool get _hasData {
    return _sessions.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.bar_chart),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StatsScreen()),
            ).then((_) => _loadData());
          },
        ),
        title: const Text('Casino Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _hasData ? _buildMainContent() : _buildEmptyState(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildToolTile(
                  context,
                  'Payouts',
                  Icons.calculate,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PayoutsScreen()),
                    );
                  },
                ),
                _buildToolTile(
                  context,
                  'Chip Calc',
                  Icons.casino,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChipCalcScreen(
                          activeSession: _activeSession,
                        ),
                      ),
                    );
                  },
                ),
                _buildToolTile(
                  context,
                  'Tip Calc',
                  Icons.attach_money,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TipCalcScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SessionCreateScreen(),
                  ),
                ).then((_) => _loadData());
              },
              child: const Text('Start new session'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.casino_outlined,
              size: 80,
              color: AppColors.muted,
            ),
            const SizedBox(height: 24),
            Text(
              'Nothing here yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Open calculators or start your first session',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Scroll to tools section (already visible in empty state)
                      setState(() {});
                    },
                    child: const Text('Open calculators'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SessionCreateScreen(),
                        ),
                      ).then((_) => _loadData());
                    },
                    child: const Text('Start session'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildToolTile(
                    context,
                    'Payouts',
                    Icons.calculate,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PayoutsScreen()),
                      );
                    },
                  ),
                  _buildToolTile(
                    context,
                    'Chip Calc',
                    Icons.casino,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChipCalcScreen(
                            activeSession: _activeSession,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildToolTile(
                    context,
                    'Tip Calc',
                    Icons.attach_money,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TipCalcScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: AppColors.accentBlue,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
