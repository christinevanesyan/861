import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/session.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StorageService _storage = StorageService();
  List<Session> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _storage.getSessions();
    setState(() {
      _sessions = sessions.where((s) => s.endedAt != null).toList();
      _isLoading = false;
    });
  }

  double get _totalResult {
    return _sessions.fold(0.0, (sum, session) => sum + session.winLoss);
  }

  double get _totalRoi {
    final totalBuyIns = _sessions.fold(0.0, (sum, s) => sum + s.totalBuyIn);
    return totalBuyIns > 0 ? (_totalResult / totalBuyIns) * 100 : 0;
  }

  Duration get _avgDuration {
    if (_sessions.isEmpty) return Duration.zero;
    final totalSeconds = _sessions.fold(0, (sum, s) {
      final duration = s.duration ?? Duration.zero;
      return sum + duration.inSeconds;
    });
    return Duration(seconds: totalSeconds ~/ _sessions.length);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 80,
                color: AppColors.muted,
              ),
              const SizedBox(height: 24),
              Text(
                'No sessions yet',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Complete a session to see statistics',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricsGrid(),
          const SizedBox(height: 24),
          Text(
            'By Game',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildGameBreakdown(),
          const SizedBox(height: 24),
          Text(
            'Best Sessions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildBestSessions(),
          const SizedBox(height: 24),
          Text(
            'Recent Sessions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildRecentSessions(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Sessions',
          _sessions.length.toString(),
          Icons.casino,
          AppColors.accentBlue,
        ),
        _buildMetricCard(
          'Total Result',
          '\$${_totalResult.toStringAsFixed(2)}',
          Icons.attach_money,
          _totalResult >= 0 ? AppColors.positive : AppColors.negative,
        ),
        _buildMetricCard(
          'ROI',
          '${_totalRoi.toStringAsFixed(1)}%',
          Icons.trending_up,
          _totalRoi >= 0 ? AppColors.positive : AppColors.negative,
        ),
        _buildMetricCard(
          'Avg Duration',
          _formatDuration(_avgDuration),
          Icons.timer,
          AppColors.muted,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontSize: 20,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBreakdown() {
    final gameStats = <String, Map<String, dynamic>>{};
    
    for (var session in _sessions) {
      if (!gameStats.containsKey(session.game)) {
        gameStats[session.game] = {
          'count': 0,
          'total': 0.0,
        };
      }
      gameStats[session.game]!['count'] = gameStats[session.game]!['count'] + 1;
      gameStats[session.game]!['total'] = gameStats[session.game]!['total'] + session.winLoss;
    }

    return Column(
      children: gameStats.entries.map((entry) {
        final count = entry.value['count'] as int;
        final total = entry.value['total'] as double;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.casino, color: AppColors.accentBlue),
            ),
            title: Text(
              entry.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('$count ${count == 1 ? "session" : "sessions"}'),
            trailing: SizedBox(
              width: 100,
              child: Text(
                '\$${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: total >= 0 ? AppColors.positive : AppColors.negative,
                      fontSize: 16,
                    ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBestSessions() {
    final sorted = List<Session>.from(_sessions)
      ..sort((a, b) => b.winLoss.compareTo(a.winLoss));
    final best = sorted.take(3).toList();

    return Column(
      children: best.map((session) => _buildSessionCard(session)).toList(),
    );
  }

  Widget _buildRecentSessions() {
    final sorted = List<Session>.from(_sessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final recent = sorted.take(5).toList();

    return Column(
      children: recent.map((session) => _buildSessionCard(session)).toList(),
    );
  }

  Widget _buildSessionCard(Session session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: session.winLoss >= 0
                ? AppColors.positive.withOpacity(0.2)
                : AppColors.negative.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            session.winLoss >= 0 ? Icons.trending_up : Icons.trending_down,
            color: session.winLoss >= 0 ? AppColors.positive : AppColors.negative,
            size: 20,
          ),
        ),
        title: Text(
          '${session.casino} • ${session.game}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy').format(session.startedAt),
        ),
        trailing: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${session.winLoss.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: session.winLoss >= 0 ? AppColors.positive : AppColors.negative,
                      fontSize: 14,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${session.roi.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
