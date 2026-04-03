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
  GpsTimeState _state = const GpsTimeState(statusMessage: 'Press Start to begin');
  bool _isListening = false;

  @override
  void dispose() {
    _subscription?.cancel();
    _plugin.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    // Request location permission first
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      setState(() {
        _state = const GpsTimeState(statusMessage: 'Location permission denied');
      });
      return;
    }

    await _plugin.startListening();
    _subscription = _plugin.gpsTimeStream.listen((state) {
      setState(() => _state = state);
    });

    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
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
              _InfoGrid(state: _state),
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

// ─── Status Card ────────────────────────────────────────────────────────────

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
              ? const Color(0xFF00E5FF).withOpacity(0.4)
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
            state.trustedTime != null
                ? _formatTime(state.trustedTime!)
                : '--:--:--',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.trustedTime != null
                ? _formatDate(state.trustedTime!)
                : 'No GPS fix yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
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
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)} (UTC${dt.timeZoneOffset.isNegative ? '-' : '+'}${_pad(dt.timeZoneOffset.inHours.abs())})';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─── Info Grid ───────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final GpsTimeState state;
  const _InfoGrid({required this.state});

  @override
  Widget build(BuildContext context) {
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
          label: 'Device Time',
          value: state.deviceTime != null
              ? _hms(state.deviceTime!.toLocal())
              : '—',
        ),
        _InfoTile(
          icon: Icons.compare_arrows,
          label: 'Clock Drift',
          value: (state.trustedTime != null && state.deviceTime != null)
              ? '${state.trustedTime!.difference(state.deviceTime!).inMilliseconds} ms'
              : '—',
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

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
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
                  style:
                      const TextStyle(fontSize: 10, color: Colors.white38),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
