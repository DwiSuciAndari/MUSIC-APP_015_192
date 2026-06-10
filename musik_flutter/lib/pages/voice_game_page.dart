import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

const primaryBlue = Color(0xFF7DA7D9);
const softPink = Color(0xFFF7A6B8);
const bg = Color(0xFFF4F5F7);

class VoiceGamePage extends StatefulWidget {
  const VoiceGamePage({super.key});

  @override
  State<VoiceGamePage> createState() => _VoiceGamePageState();
}

class _VoiceGamePageState extends State<VoiceGamePage> {
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _sub;

  double db = 0;
  int score = 0;
  bool isListening = false;

  List<int> history = [];

  String getLoudnessText(double currentDb) {
    if (!isListening) return "Tekan Start";
    if (currentDb < 50) return "Pelan (Min) 🤫";
    if (currentDb < 75) return "Sedang (Mid) 🗣️";
    return "Kencang! (Max) 🔥";
  }

  Color getLoudnessColor(double currentDb) {
    if (!isListening) return Colors.grey;
    if (currentDb < 50) return Colors.grey.shade400;
    if (currentDb < 75) return primaryBlue;
    return softPink;
  }

  Future<void> start() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Izin mikrofon diperlukan!")),
      );
      return;
    }

    score = 0;
    _noiseMeter = NoiseMeter();

    _sub = _noiseMeter!.noise.listen((event) {
      setState(() {
        db = event.meanDecibel;
        if (db > 75) score++;
      });
    });

    setState(() => isListening = true);
  }

  void stop() {
    _sub?.cancel();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (score == 0 && db > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Yah, suaramu kurang kenceng! 😅 Coba lagi yuk!"),
          backgroundColor: softPink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.all(20),
        ),
      );
    } else if (score > 0) {
      history.insert(0, score);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mantap kenceng banget! Kamu dapat $score poin! 🎉"),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }

    setState(() {
      isListening = false;
      db = 0;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double circleSize = (120 + (db * 1.5)).clamp(120.0, 280.0);
    Color currentColor = getLoudnessColor(db);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Voice Game",
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        color:
                            currentColor.withOpacity(isListening ? 0.3 : 0.1),
                        shape: BoxShape.circle,
                        border: isListening
                            ? Border.all(color: currentColor, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          size: 50,
                          color: isListening ? currentColor : primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Teks Desibel
                    Text(
                      isListening ? "${db.toStringAsFixed(1)} dB" : "0.0 dB",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isListening ? currentColor : Colors.grey,
                      ),
                    ),

                    // Teks Status (Min / Mid / Max)
                    if (isListening)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          getLoudnessText(db),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: currentColor,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        "Skor: $score",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isListening ? softPink : primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isListening ? stop : start,
                      child: Text(
                        isListening ? "STOP LISTENING" : "START GAME",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Riwayat Skor",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            score = 0;
                            history.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh,
                            size: 18, color: Colors.grey),
                        label: const Text("Reset",
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                  if (history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text("Belum ada riwayat permainan.",
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: history.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: primaryBlue.withOpacity(0.3)),
                          ),
                          child: Text(
                            "$e Poin",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryBlue),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}