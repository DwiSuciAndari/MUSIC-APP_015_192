import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'wishlist_controller.dart';
import '../services/lyrics_service.dart';
import 'converter_page.dart';

class DetailPage extends StatefulWidget {
  final dynamic song;
  const DetailPage({super.key, required this.song});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String lyrics = "Loading...";
  final player = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    loadLyrics();
    _saveToHistory();
  }

  void _saveToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history_songs') ?? [];

    // Hapus jika sudah ada agar posisinya naik ke paling atas (terbaru)
    history.removeWhere((item) => jsonDecode(item)['id'] == widget.song['id']);
    history.insert(0, jsonEncode(widget.song));

    // Simpan maksimal 15 lagu terakhir agar memori tidak penuh
    if (history.length > 15) history = history.sublist(0, 15);

    await prefs.setStringList('history_songs', history);
  }

  void _showAIFact() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFF7A6B8)),
                SizedBox(width: 10),
                Text("Fakta Aura AI",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037))),
              ],
            ),
            const SizedBox(height: 20),
            FutureBuilder<http.Response>(
              future: http.post(
                  Uri.parse(
                      'http://172.20.10.2:3000/api/chat'), // URL server lokal (Aura AI)
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    "message":
                        "Berikan 1 fakta unik singkat tentang lagu ${widget.song['title']} oleh ${widget.song['artist']['name']}."
                  })),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const CircularProgressIndicator(
                      color: Color(0xFF7DA7D9));
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.statusCode != 200)
                  return const Text("Gagal memuat fakta AI.");

                final data = jsonDecode(snapshot.data!.body);
                return Text(data['result'] ?? "Fakta tidak ditemukan.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, height: 1.5, color: Colors.black87));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void loadLyrics() async {
    final l = await getLyrics(
      widget.song['title'],
      widget.song['artist']['name'],
    );

    setState(() {
      if (l.toLowerCase().contains("tidak") ||
          l.toLowerCase().contains("gagal")) {
        lyrics = "Lirik belum tersedia untuk lagu ini 😢\n\nCoba lagu lain ya!";
      } else {
        lyrics = l;
      }
    });
  }

  void play() async {
    final url = widget.song['preview'];

    if (url == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Preview tidak tersedia")));
      return;
    }

    if (isPlaying) {
      await player.pause();
    } else {
      await player.play(UrlSource(url));
    }

    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.song;
    // Gunakan Get.put agar controller otomatis dibuat jika belum ada
    final wishlistController = Get.put(WishlistController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8FAADC),
        elevation: 0,
        actions: [
          // Obx akan merender ulang bagian ini secara otomatis ketika data berubah
          Obx(() {
            final isLiked = wishlistController.isLiked(s['id']);
            return IconButton(
              icon: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked ? Colors.redAccent : Colors.white),
              onPressed: () => wishlistController.toggleLike(s),
            );
          })
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(s['album']['cover'], height: 220),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            s['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(
            s['artist']['name'],
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),

          const SizedBox(height: 25),

          // Row untuk menjejajarkan tombol Preview 30s dan Tombol Premium
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: play,
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(isPlaying ? "Pause" : "Preview 30s"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8FAADC),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: () {
                  // Hentikan musik preview jika sedang menyala
                  if (isPlaying) {
                    play();
                  }
                  // Arahkan ke halaman Premium (Converter)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConvertPage()),
                  );
                },
                icon: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.amber),
                label: const Text("Unlock Full"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF5D4037), // Warna cokelat elegan
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- Tombol AI Fact ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: _showAIFact,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7A6B8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFF7A6B8)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF5D4037)),
                    SizedBox(width: 8),
                    Text("Tanya Fakta Lagu ke Aura AI ✨",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037))),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFDFDFD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  lyrics,
                  style: const TextStyle(
                    height: 1.6,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
