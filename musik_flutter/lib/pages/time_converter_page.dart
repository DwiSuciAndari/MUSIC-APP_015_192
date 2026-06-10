import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

const primaryBlue = Color(0xFF7DA7D9);
const softPink = Color(0xFFF7A6B8);
const deepBrown = Color(0xFF5D4037);
const bg = Color(0xFFF4F5F7);

class TimeConverterPage extends StatefulWidget {
  const TimeConverterPage({super.key});

  @override
  State<TimeConverterPage> createState() => _TimeConverterPageState();
}

class _TimeConverterPageState extends State<TimeConverterPage> {
  double _currentHours = 12.0;
  double _rotation = 0.0;

  final AudioPlayer _player = AudioPlayer();
  String? _playingUrl;
  List<dynamic> _moodTracks = [];
  bool _isLoadingMood = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentHours =
        now.hour + now.minute / 60.0; // Ambil waktu asli perangkat saat ini
    _fetchMoodTracks(_currentHours); // Fetch awal
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _getMoodQuery(double hours) {
    int h = hours.floor() % 24;
    if (h >= 5 && h < 11) return "Morning Booster Pop";
    if (h >= 11 && h < 15) return "Work Focus Lofi";
    if (h >= 15 && h < 19) return "Chill Sunset Indie";
    if (h >= 19 && h < 24) return "Night Party EDM";
    return "Midnight Lullaby Piano";
  }

  String _getMoodDescription(double hours) {
    int h = hours.floor() % 24;
    if (h >= 5 && h < 11) return "Indonesia sedang memulai hari. Semangat! ☀️";
    if (h >= 11 && h < 15) return "Jam sibuk dan fokus beraktivitas! ☕";
    if (h >= 15 && h < 19) return "Waktunya bersantai menikmati sore. 🌇";
    if (h >= 19 && h < 24) return "Malam hari waktunya asik-asikan! 🪩";
    return "Indonesia sedang terlelap, waktunya istirahat... 🌙";
  }

  Future<void> _fetchMoodTracks(double hours) async {
    setState(() => _isLoadingMood = true);
    String query = _getMoodQuery(hours);
    final url = Uri.parse("https://api.deezer.com/search?q=$query&limit=4");

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          _moodTracks = jsonDecode(res.body)['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching mood: $e");
    } finally {
      setState(() => _isLoadingMood = false);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Geser horizontal untuk memutar piringan dan mengubah jam
      _currentHours += details.delta.dx * 0.02;
      if (_currentHours >= 24) _currentHours -= 24;
      if (_currentHours < 0) _currentHours += 24;

      _rotation += details.delta.dx * 0.02; // Efek visual putaran
    });
  }

  String _formatTime(double decimalHours) {
    double total = decimalHours;
    if (total >= 24) total -= 24;
    if (total < 0) total += 24;

    int h = total.floor();
    int m = ((total - h) * 60).floor();

    String hh = h.toString().padLeft(2, '0');
    String mm = m.toString().padLeft(2, '0');

    return "$hh:$mm";
  }

  Future<void> _selectTime(BuildContext context) async {
    double total = _currentHours;
    if (total >= 24) total -= 24;
    if (total < 0) total += 24;

    int h = total.floor();
    int m = ((total - h) * 60).floor();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: deepBrown,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _currentHours = picked.hour + picked.minute / 60.0;
      });
      _fetchMoodTracks(_currentHours);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Vinyl Time Spinner",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text("Putar Piringan Hitam!",
                style: TextStyle(
                    color: deepBrown,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            const Text("Geser (swipe) piringan untuk mengatur jam",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 10),

            // Tombol Kontrol Waktu
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _currentHours = now.hour + now.minute / 60.0;
                    });
                    _fetchMoodTracks(_currentHours);
                  },
                  icon: const Icon(Icons.restore, color: primaryBlue),
                  label: const Text("Waktu Sekarang",
                      style: TextStyle(
                          color: primaryBlue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () => _selectTime(context),
                  icon: const Icon(Icons.access_time_rounded, color: softPink),
                  label: const Text("Set Manual",
                      style: TextStyle(
                          color: softPink, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- VINYL SPINNER INTERAKTIF ---
            GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: (details) => _fetchMoodTracks(_currentHours),
              child: Transform.rotate(
                angle: _rotation,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1C1C1C),
                    border: Border.all(color: Colors.grey.shade800, width: 8),
                    boxShadow: [
                      BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10)
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Garis-garis Vinyl
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 1),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 1),
                        ),
                      ),
                      // Label Tengah Piringan
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: softPink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: const Icon(Icons.music_note_rounded,
                            color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // --- DIGITAL CLOCKS ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5))
                ],
              ),
              child: Column(
                children: [
                  _buildTimeCard("WIB (Lokal)", _currentHours, softPink),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTimeCard(
                              "London", _currentHours - 7, primaryBlue)),
                      const SizedBox(width: 15),
                      Expanded(
                          child: _buildTimeCard(
                              "WITA", _currentHours + 1, deepBrown)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTimeCard(
                              "WIT", _currentHours + 2, Colors.orangeAccent)),
                      const SizedBox(width: 15),
                      Expanded(
                          child: _buildTimeCard(
                              "Tokyo", _currentHours + 2, Colors.purpleAccent)),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // --- GLOBAL VIBE SYNC ---
                  const Divider(),
                  const SizedBox(height: 15),
                  const Text("Vibe Sync: Indonesia",
                      style: TextStyle(
                          color: deepBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(_getMoodDescription(_currentHours),
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),

                  if (_isLoadingMood)
                    const CircularProgressIndicator(color: primaryBlue)
                  else if (_moodTracks.isNotEmpty)
                    Column(
                      children: _moodTracks.map((song) {
                        bool isPlaying = _playingUrl == song['preview'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(15)),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                    song['album']['cover_small'],
                                    width: 40,
                                    height: 40),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(song['title'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text(song['artist']['name'],
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                    isPlaying
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_fill_rounded,
                                    color: isPlaying ? softPink : primaryBlue),
                                onPressed: () async {
                                  if (song['preview'] == null) return;
                                  if (isPlaying) {
                                    await _player.pause();
                                    setState(() => _playingUrl = null);
                                  } else {
                                    await _player
                                        .play(UrlSource(song['preview']));
                                    setState(
                                        () => _playingUrl = song['preview']);
                                  }
                                },
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String zone, double timeVal, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(zone,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            _formatTime(timeVal),
            style: TextStyle(
                color: color, fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
