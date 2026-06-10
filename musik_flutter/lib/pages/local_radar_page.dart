import 'dart:async';
import '../services/deezer_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:audioplayers/audioplayers.dart';

const primaryBlue = Color(0xFF7DA7D9);
const softPink = Color(0xFFF7A6B8);
const deepBrown = Color(0xFF5D4037);
const bg = Color(0xFFF4F5F7);

class LocalRadarPage extends StatefulWidget {
  const LocalRadarPage({super.key});

  @override
  State<LocalRadarPage> createState() => _LocalRadarPageState();
}

class _LocalRadarPageState extends State<LocalRadarPage> {
  String locationMessage = "Mendeteksi aura lokasimu...";
  String city = "";
  bool isLoading = false;

  final AudioPlayer _player = AudioPlayer();
  String? _playingUrl;
  List<dynamic> _hitsSongs = [];
  List<dynamic> _chillSongs = [];
  List<dynamic> _nightSongs = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => isLoading = true);

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. Minta Izin Dulu
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          locationMessage =
              "Izin lokasi ditolak. Buka pengaturan HP untuk mengizinkan.";
          isLoading = false;
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationMessage =
              "Izin ditolak permanen. Izinkan manual di Pengaturan HP.";
          isLoading = false;
        });
        return;
      }

      // 2. Cek apakah GPS (Location Service) menyala
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationMessage = "GPS mati. Harap nyalakan lokasi/GPS di HP Anda.";
          isLoading = false;
        });
        return;
      }

      // 3. Ambil titik kordinat (Dengan Timeout)
      Position? position;
      try {
        // Coba ambil lokasi terakhir dulu agar lebih cepat
        position = await Geolocator.getLastKnownPosition();

        // Jika kosong, cari lokasi baru dengan akurasi medium (jangan high)
        position ??= await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8));
      } catch (_) {
        position = await Geolocator.getLastKnownPosition(); // Fallback akhir
      }

      if (position != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
                position.latitude, position.longitude)
            .timeout(const Duration(seconds: 10)); // Tambahkan batas waktu

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          String detectedCity = place.subAdministrativeArea
                  ?.replaceAll("Kabupaten ", "")
                  .replaceAll("Kota ", "") ??
              place.locality ??
              "Kotamu";

          // Pindahkan proses await (async) ke LUAR setState
          var hits = (await searchMusic("Hits Indonesia")).take(5).toList();
          var chill = (await searchMusic("Indie Chill")).take(5).toList();
          var night = (await searchMusic("Lofi Beats")).take(5).toList();

          setState(() {
            city = detectedCity;
            locationMessage = "Terdeteksi kamu ada di $city!";
            _hitsSongs = hits;
            _chillSongs = chill;
            _nightSongs = night;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          locationMessage =
              "Gagal melacak titik GPS. Coba berada di luar ruangan.";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("GPS Error: $e");
      setState(() {
        locationMessage = "Sistem lokasi belum siap/izin belum lengkap.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Geo-Vibe Music",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: primaryBlue,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- GEO-VIBE CARD ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: city.isNotEmpty
                      ? [softPink, const Color(0xFFFFA4A2)]
                      : [primaryBlue, const Color(0xFF90CAF9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                      color: (city.isNotEmpty ? softPink : primaryBlue)
                          .withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                children: [
                  Icon(
                      city.isNotEmpty
                          ? Icons.headphones_rounded
                          : Icons.location_searching_rounded,
                      size: 60,
                      color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    locationMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2),
                  ),
                  if (city.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                          "Ini rekomendasi playlist yang cocok buat nemenin harimu di sini.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (city.isNotEmpty) ...[
              const Text("Rekomendasi Playlist Lokal",
                  style: const TextStyle(
                      color: deepBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 15),
              _buildPlaylistCard(context, "Chill Sore di $city",
                  "Lagu indie santai buat ngelepas penat.", _chillSongs),
              _buildPlaylistCard(context, "$city Hits Hari Ini",
                  "Lagu-lagu yang lagi sering diputar di kotamu.", _hitsSongs),
              _buildPlaylistCard(context, "Night Drive $city",
                  "Vibe perjalanan malam menyusuri jalanan kota.", _nightSongs),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(
      BuildContext context, String title, String desc, List<dynamic> songs) {
    return InkWell(
      onTap: () {
        if (songs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Memuat lagu dari Deezer, tunggu sebentar...")));
          return;
        }
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) =>
              StatefulBuilder(builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: deepBrown),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  ...songs.map((song) {
                    bool isPlaying = _playingUrl == song['preview'];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(song['album']['cover_small']),
                      ),
                      title: Text(song['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: deepBrown)),
                      subtitle: Text(song['artist']['name'],
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      trailing: IconButton(
                        icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: isPlaying ? softPink : primaryBlue,
                            size: 36),
                        onPressed: () async {
                          if (song['preview'] == null) return;
                          if (isPlaying) {
                            await _player.pause();
                            setSheetState(() => _playingUrl = null);
                          } else {
                            await _player.play(UrlSource(song['preview']));
                            setSheetState(() => _playingUrl = song['preview']);
                          }
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: softPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.queue_music_rounded,
                  color: softPink, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: deepBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill_rounded,
                color: primaryBlue, size: 36),
          ],
        ),
      ),
    );
  }
}
