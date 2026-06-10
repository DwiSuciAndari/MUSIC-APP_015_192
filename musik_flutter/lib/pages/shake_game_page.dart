import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeGamePage extends StatefulWidget {
  const ShakeGamePage({super.key});

  @override
  State<ShakeGamePage> createState() => _ShakeGamePageState();
}

class _ShakeGamePageState extends State<ShakeGamePage> {
  int score = 0;
  bool isPlaying = false;
  int timeLeft = 10;
  Timer? _timer;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;

  void startGame() {
    setState(() {
      score = 0;
      timeLeft = 10;
      isPlaying = true;
    });

    // Timer hitung mundur 10 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        stopGame();
      }
    });

    // Mendengarkan sensor Accelerometer
    _accelerometerSub = accelerometerEventStream().listen((event) {
      // Menghitung kekuatan guncangan (magnitude)
      double magnitude =
          sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

      // Angka 9.8 adalah gravitasi bumi normal. Jika lebih dari 20, berarti HP diguncang keras!
      if (magnitude > 20) {
        setState(() {
          score++;
        });
      }
    });
  }

  void stopGame() {
    _timer?.cancel();
    _accelerometerSub?.cancel();
    setState(() => isPlaying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Waktu habis! Skor akhirmu: $score"),
        backgroundColor: const Color(0xFF7DA7D9),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text("Maracas Shake Game",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7DA7D9),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vibration, size: 80, color: Color(0xFF7DA7D9)),
            const SizedBox(height: 20),
            const Text(
              "Kocok HP-mu layaknya Maracas!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 15)
                ],
              ),
              child: Text(
                "$score",
                style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7DA7D9)),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              isPlaying
                  ? "Waktu tersisa: $timeLeft detik"
                  : "Siap mengguncang?",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            if (!isPlaying)
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7A6B8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: startGame,
                  child: const Text("MULAI",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
