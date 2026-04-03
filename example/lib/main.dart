import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gps_time_plugin/gps_time_plugin.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const GpsTimeExampleApp());
}

class GpsTimeExampleApp extends StatelessWidget {
  const GpsTimeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Time Plugin Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
      ),
      home: const GpsTimeHomePage(),
    );
  }
}

class GpsTimeHomePage extends StatefulWidget {
  const GpsTimeHomePage({super.key});

  @override
  State<GpsTimeHomePage> createState() => _GpsTimeHomePageState();
}

class _GpsTimeHomePageState extends State<GpsTimeHomePage> {
  final _plugin = GpsTimePlugin();

  StreamSubscription<GpsTimeState>? _subscription;
  Timer? _clockTimer;

  GpsTimeState _state = const GpsTimeState(statusMessage: 'Press Start to begin');

  /// Updated every second by [_clockTimer] — independent of the GPS stream so
  /// clock drift is visible immediately after a manual time change.
  DateTime _deviceNow = DateTime.now();
  bool _isListening = false;

  @override
  void dispose() {
    _subscription?.cancel();
    _clockTimer?.cancel();
    _plugin.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      setState(() {
        _state = const GpsTimeState(
          statusMessage: 'Location permission denied. Enable in Settings.',
        );
      });
      return;
    }

    // ✅ Subscribe FIRST so we never miss the initial status event.
    // EventChannel onListen fires when .listen() is called below,
    // wiring the native combine flow before startListening() gets called.
    _subscription = _plugin.gpsTimeStream.listen(
      (state) => setState(() => _state = state),
      onError: (e) => setState(
        () => _state = GpsTimeState(statusMessage: 'Stream error: $e'),
      ),
    );

    await _plugin.startListening();

    // ✅ Tick every second so Device Time and Clock Drift update live,
    // making manual time-change effects immediately visible in the UI.
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _deviceNow = DateTime.now());
    });

    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    _clockTimer?.cancel();
    _clockTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _plugin.stopListening();
    setState(() {
      _isListening = false;
      _state = const GpsTimeState(statusMessage: 'Stopped');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Compute drift against live device clock so it updates every second.
    final drift = _state.trustedTime != null
        ? _state.trustedTime!.difference(_deviceNow.toUtc())
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1224),
        title: const Text(
          'GPS Time Plugin',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusCard(state: _state),
              const SizedBox(height: 20),
              _InfoGrid(
                state: _state,
                deviceNow: _deviceNow,
                drift: drift,
              ),
              const Spacer(),
              _ControlButton(
                isListening: _isListening,
                onStart: _startListening,
                onStop: _stopListening,
                accentColor: cs.primary,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Card ─────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final GpsTimeState state;
  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasFix = state.trustedTime != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasFix
              ? [const Color(0xFF003D4F), const Color(0xFF00BCD4)]
              : [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFix
              ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
              : Colors.white12,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasFix ? Icons.gps_fixed : Icons.gps_not_fixed,
            size: 48,
            color: hasFix ? const Color(0xFF00E5FF) : Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            hasFix ? _formatTime(state.trustedTime!) : '--:--:--',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasFix ? _formatDate(state.trustedTime!) : 'No GPS fix yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              state.statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${_pad(local.hour)}:${_pad(local.minute)}:${_pad(local.second)}';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final h = offset.inHours.abs();
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)} (UTC$sign${_pad(h)})';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─── Info Grid ───────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final GpsTimeState state;
  final DateTime deviceNow;
  final Duration? drift;

  const _InfoGrid({
    required this.state,
    required this.deviceNow,
    required this.drift,
  });

  @override
  Widget build(BuildContext context) {
    final driftMs = drift?.inMilliseconds;
    final driftText = driftMs != null
        ? '${driftMs > 0 ? '+' : ''}$driftMs ms'
        : '—';
    // Turn red when drift exceeds 5 seconds — indicates clock manipulation
    final bigDrift = driftMs != null && driftMs.abs() > 5000;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        _InfoTile(
          icon: Icons.my_location,
          label: 'Accuracy',
          value: state.accuracy != null
              ? '${state.accuracy!.toStringAsFixed(1)} m'
              : '—',
        ),
        _InfoTile(
          icon: Icons.timer_outlined,
          label: 'Fix Age',
          value: state.ageSeconds != null ? '${state.ageSeconds}s' : '—',
        ),
        _InfoTile(
          icon: Icons.access_time,
          // ✅ Uses live _deviceNow from 1s timer, not the stale stream value
          label: 'Device Time',
          value: _hms(deviceNow),
        ),
        _InfoTile(
          icon: Icons.compare_arrows,
          label: 'Clock Drift',
          value: driftText,
          valueColor: bigDrift ? Colors.redAccent : null,
        ),
      ],
    );
  }

  String _hms(DateTime dt) =>
      '${_p(dt.hour)}:${_p(dt.minute)}:${_p(dt.second)}';
  String _p(int n) => n.toString().padLeft(2, '0');
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1224),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00E5FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Control Button ──────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final Color accentColor;

  const _ControlButton({
    required this.isListening,
    required this.onStart,
    required this.onStop,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isListening
          ? OutlinedButton.icon(
              key: const ValueKey('stop'),
              onPressed: onStop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop GPS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          : FilledButton.icon(
              key: const ValueKey('start'),
              onPressed: onStart,
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Start GPS'),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
    );
  }
}
