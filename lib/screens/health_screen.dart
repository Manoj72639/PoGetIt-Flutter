import 'dart:async';

import 'package:flutter/material.dart';
import '../services/health_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with WidgetsBindingObserver {
  final HealthService _healthService = HealthService();

  static const int dailyGoal = 5000;
  static const Duration refreshInterval = Duration(seconds: 15);

  Timer? _timer;

  int? _steps;
  DateTime? _lastUpdated;
  String? _error;

  bool _isRefreshing = false;
  bool _isInitialLoading = true;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTracking();
  }

  Future<void> _startTracking() async {
    _timer?.cancel();

    await _refreshSteps();

    if (!mounted || !_connected) return;

    _timer = Timer.periodic(refreshInterval, (_) => _refreshSteps());
  }

  Future<void> _refreshSteps() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final result = await _healthService.getTodaySteps();

      if (!mounted) return;

      setState(() {
        _steps = result ?? 0;
        _connected = true;
        _error = null;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _connected = false;
      });

      _timer?.cancel();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTracking();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps ?? 0;
    final progress = (steps / dailyGoal).clamp(0.0, 1.0);
    final remaining = (dailyGoal - steps).clamp(0, dailyGoal);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        title: const Text(
          'Health Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh steps',
            onPressed: _isRefreshing ? null : _refreshSteps,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSteps,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Your daily activity',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Stay active and keep moving toward your goal.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Main steps card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_walk_rounded,
                    color: Colors.teal,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Today's Steps",
                    style: TextStyle(fontSize: 17, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      _steps == null ? '--' : '$steps',
                      key: ValueKey(steps),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF152B2A),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Daily goal: $dailyGoal steps',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 650),
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(12),
                        backgroundColor: const Color(0xFFE4F2EF),
                        color: Colors.teal,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '${(progress * 100).round()}% of daily goal',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.flag_outlined,
                    label: 'Remaining',
                    value: '$remaining',
                    unit: 'steps',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.track_changes_outlined,
                    label: 'Goal',
                    value: '$dailyGoal',
                    unit: 'steps',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Icon(
                  _connected
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: _connected ? Colors.teal : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connected
                        ? 'Connected to Health Connect'
                        : 'Health Connect not connected',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (_isRefreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              _lastUpdated == null
                  ? 'Waiting for first update'
                  : 'Last checked at '
                        '${TimeOfDay.fromDateTime(_lastUpdated!).format(context)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),

            const SizedBox(height: 8),

            const Text(
              'Automatically checks for new data every 15 seconds.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),

            if (_isInitialLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isRefreshing ? null : _startTracking,
                child: const Text('Reconnect Health Connect'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
