import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourist_app/services/firebase_service.dart';
import 'package:vibration/vibration.dart';
import 'loginScreen.dart';

class MainScreen extends StatefulWidget {
  final String token;
  const MainScreen({super.key, required this.token});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Timer? _safetyTimer;
  int _timerDuration = 3600; // 1 hour in seconds
  int _remainingTime = 3600;

  @override
  void dispose() {
    _safetyTimer?.cancel();
    super.dispose();
  }

  Future<Position> _getCurrentLocation() async {
    // ... (This function remains the same)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _logout(BuildContext context) async {
    // ... (This function remains the same)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _triggerAlert(String alertType, String title) async {
    try {
      Vibration.vibrate(duration: 500); // Haptic feedback
      final Position position = await _getCurrentLocation();

      FirebaseService.sendAlert(
        touristId: widget.token,
        latitude: position.latitude,
        longitude: position.longitude,
        alertType: alertType,
        title: title,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title Alert Sent Successfully!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _startSafetyTimer() {
    _safetyTimer?.cancel();
    _remainingTime = _timerDuration;
    _safetyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _safetyTimer?.cancel();
        _triggerAlert('safety_timer_expired', 'Safety Timer Expired');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Safety Timer Started!')),
    );
  }

  void _stopSafetyTimer() {
    _safetyTimer?.cancel();
    setState(() {
      _remainingTime = _timerDuration;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Safety Timer Cancelled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourist Safety'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Panic Button
            _buildPanicButton(),
            const SizedBox(height: 24),
            // Other Alert Types
            _buildAlertGrid(),
            const SizedBox(height: 24),
            // Safety Timer
            _buildSafetyTimerCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPanicButton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _triggerAlert('panic', 'Panic Alert'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 60, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'SEND PANIC ALERT',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildAlertButton('Medical', Icons.local_hospital, 'medical_emergency'),
        _buildAlertButton('Fire', Icons.whatshot, 'fire_emergency'),
        _buildAlertButton('Crime', Icons.local_police, 'theft_crime'),
        _buildAlertButton('Lost', Icons.map, 'lost_missing_person'),
      ],
    );
  }

  Widget _buildAlertButton(String title, IconData icon, String alertType) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _triggerAlert(alertType, '$title Emergency'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue[800]),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTimerCard() {
    bool isTimerRunning = _safetyTimer?.isActive ?? false;
    String timerText =
        '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Safety Timer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              isTimerRunning ? timerText : '1 Hour',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            isTimerRunning
                ? ElevatedButton.icon(
                    onPressed: _stopSafetyTimer,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Timer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _startSafetyTimer,
                    icon: const Icon(Icons.timer),
                    label: const Text('Start 1-Hour Timer'),
                  ),
          ],
        ),
      ),
    );
  }
}
