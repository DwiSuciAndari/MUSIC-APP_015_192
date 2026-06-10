import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_page.dart';
import 'converter_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'time_converter_page.dart';
import 'local_radar_page.dart';
import 'game_page.dart';
import 'detail_page.dart';
import 'voice_game_page.dart';
import 'network_sensor_page.dart';
import 'login_page.dart';
import '../services/notif_service.dart';

const Color softPink = Color(0xFFF7A6B8);
const Color bg = Color(0xFFF4F5F7);
const Color deepBrown = Color(0xFF5D4037);
const Color primaryBlue = Color(0xFF7DA7D9);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboard(),
    const ProfilePage(),
    const SaranKesanPage(),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      _showLogoutDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Konfirmasi Keluar",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: softPink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                // Hapus data login dari SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLogin',
                    false); // Hanya ubah status login, jangan clear() semua

                if (!context.mounted) return;
                // Kembali ke halaman login dan hapus semua halaman sebelumnya
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child:
                  const Text("Keluar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.orange,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Container(
                margin: const EdgeInsets.only(bottom: 4),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _selectedIndex == 1
                          ? primaryBlue
                          : Colors.transparent,
                      width: 2),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              label: 'Profil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_rounded),
              label: 'Ulasan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: 'Keluar',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  StreamSubscription? _accelerometerSub;
  Timer? _decayTimer;
  double _energyLevel = 0.0;
  bool _isEnergyFull = false;
  Map<String, dynamic>? _detectedAura;
  final Random _random = Random();

  // Daftar Aura yang bisa terdeteksi
  final List<Map<String, dynamic>> _auras = [
    {
      "name": "Aura Biru Tenang",
      "description":
          "Kamu sedang dalam mode damai. Waktunya mendengarkan lagu yang menenangkan jiwa.",
      "color": const Color(0xFF4FC3F7), // Light Blue
      "icon": Icons.self_improvement_rounded,
    },
    {
      "name": "Aura Merah Semangat",
      "description":
          "Energi membara! Putar playlist yang bikin kamu makin bersemangat.",
      "color": const Color(0xFFE57373), // Light Red
      "icon": Icons.local_fire_department_rounded,
    },
    {
      "name": "Aura Hijau Kreatif",
      "description":
          "Ide-ide cemerlang bermunculan. Stimulasi otakmu dengan musik instrumental.",
      "color": const Color(0xFF81C784), // Light Green
      "icon": Icons.lightbulb_rounded,
    },
    {
      "name": "Aura Emas Bahagia",
      "description":
          "Kamu sedang bersinar! Rayakan momen ini dengan lagu-lagu pop ceria.",
      "color": const Color(0xFFFFD54F), // Amber
      "icon": Icons.celebration_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _accelerometerSub = accelerometerEventStream().listen((event) {
      if (_isEnergyFull) return;

      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > 12) {
        setState(() {
          _energyLevel += (magnitude - 10) * 1.5;
          if (_energyLevel >= 100) {
            _energyLevel = 100;
            _triggerEnergyFull();
          }
        });
      }
    });

    _decayTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isEnergyFull && _energyLevel > 0) {
        setState(() {
          _energyLevel -= 0.5;
          if (_energyLevel < 0) _energyLevel = 0;
        });
      }
    });
  }

  void _triggerEnergyFull() {
    final detected = _auras[_random.nextInt(_auras.length)];

    setState(() {
      _isEnergyFull = true;
      _detectedAura = detected;
    });

    NotifService.show(
      "Aura Terdeteksi! ✨",
      "Kamu sedang memancarkan ${_detectedAura!['name']}. Cek rekomendasinya!",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Aura-mu terdeteksi: ${_detectedAura!['name']}"),
        backgroundColor: _detectedAura!['color'],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _energyLevel = 0;
          _isEnergyFull = false;
          _detectedAura = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    _decayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          backgroundColor: bg,
          floating: true,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Row(
              children: [
                const Text("AuraMusic",
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: primaryBlue)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfilePage())),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: softPink.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: softPink, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildSearchBar(context),
                const SizedBox(height: 20),
                _buildMainBanner(context),
                const SizedBox(height: 30),
                _sectionHeader("Asisten Pintar"),
                const SizedBox(height: 15),
                _buildAICard(context),
                const SizedBox(height: 25),
                _sectionHeader("Terakhir Diputar"),
                _buildMusicHorizontalList(context, 'history_songs'),
                const SizedBox(height: 20),
                _sectionHeader("Wishlist Kamu ❤️"),
                _buildMusicHorizontalList(context, 'liked_songs'),
                const SizedBox(height: 25),
                _sectionHeader("Fitur Pendukung"),
                const SizedBox(height: 15),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1.1,
                  children: [
                    _buildQuickMenu(
                        context,
                        "Upgrade Premium",
                        "Gabung sekarang",
                        Icons.currency_exchange_rounded,
                        const ConvertPage()),
                    _buildQuickMenu(
                        context,
                        "Time Vibes",
                        "Cek vibe lagu tiap jam",
                        Icons.access_time_rounded,
                        const TimeConverterPage()),
                    _buildQuickMenu(
                        context,
                        "Discover Nearby",
                        "Playlist hits kotamu",
                        Icons.location_on_rounded,
                        const LocalRadarPage()),
                    _buildQuickMenu(
                        context,
                        "Koneksi & Data",
                        "Pantau radar internetmu",
                        Icons.wifi_tethering_rounded,
                        const NetworkPage()),
                  ],
                ),
                const SizedBox(height: 25),
                _sectionHeader("Hiburan"),
                const SizedBox(height: 15),
                _buildWideMenu(
                    context,
                    "Beat Challenge",
                    "Mainkan kuis & adu ritme",
                    Icons.videogame_asset_rounded,
                    const GamePage()),
                const SizedBox(height: 12),
                _buildWideMenu(context, "Sing Along", "Uji kestabilan vokalmu",
                    Icons.mic_external_on_rounded, const VoiceGamePage()),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w900, color: deepBrown));
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SearchPage()));
        setState(
            () {}); // Me-refresh list History & Wishlist saat kembali ke Home
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: primaryBlue, size: 24),
            const SizedBox(width: 15),
            Text("Pencarian lagu dan artis...",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBanner(BuildContext context) {
    Color bannerColor = _isEnergyFull && _detectedAura != null
        ? _detectedAura!['color']
        : (Color.lerp(primaryBlue, softPink, _energyLevel / 100) ??
            primaryBlue);

    return Transform.translate(
      offset: Offset(
          _energyLevel > 0 && !_isEnergyFull ? (_energyLevel % 5 - 2.5) : 0, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [bannerColor, bannerColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: bannerColor.withOpacity(0.3),
              blurRadius: 10 + (_energyLevel * 0.2),
              spreadRadius: _energyLevel * 0.1,
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.1 + (_energyLevel / 200).clamp(0, 0.4),
                child: Icon(
                    _isEnergyFull && _detectedAura != null
                        ? _detectedAura!['icon']
                        : Icons.music_note_rounded,
                    size: 150,
                    color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEnergyFull && _detectedAura != null
                        ? "AURA TERDETEKSI! ✨"
                        : _energyLevel > 0
                            ? "Terus Goyang! 🔥"
                            : "Aura Energy Meter",
                    style: const TextStyle(
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEnergyFull && _detectedAura != null
                        ? _detectedAura!['description']
                        : "Goyangkan HP untuk mengisi energi",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _energyLevel / 100,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isEnergyFull ? Colors.yellowAccent : Colors.white,
                      ),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEnergyFull && _detectedAura != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_detectedAura!['name'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    )
                  else
                    Text(
                      "Intensitas: ${_energyLevel.toInt()}%",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAICard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ChatPage())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [softPink, primaryBlue]),
                borderRadius: BorderRadius.circular(15),
              ),
              child:
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Aura AI",
                      style: TextStyle(
                          color: deepBrown,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  SizedBox(height: 4),
                  Text(
                      "Chatbot AI yang membantumu memilih & merekomendasi lagu",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicHorizontalList(BuildContext context, String prefsKey) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(
              height: 140,
              child:
                  Center(child: CircularProgressIndicator(color: primaryBlue)));

        List<String> rawData = snapshot.data!.getStringList(prefsKey) ?? [];
        if (rawData.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 10),
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Center(
              child: Text(
                  prefsKey == 'history_songs'
                      ? "Belum ada lagu yang diputar."
                      : "Wishlist masih kosong.",
                  style: const TextStyle(color: Colors.grey)),
            ),
          );
        }

        List<dynamic> songs = rawData.map((e) => jsonDecode(e)).toList();

        return Container(
          margin: const EdgeInsets.only(top: 15),
          height: 145,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              var s = songs[index];
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DetailPage(song: s)));
                  setState(() {}); // Refresh setelah balik dari detail
                },
                child: Container(
                  width: 105,
                  margin: const EdgeInsets.only(right: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          s['album']?['cover_medium'] ??
                              s['album']?['cover'] ??
                              '',
                          height: 105,
                          width: 105,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              height: 105,
                              width: 105,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.music_note,
                                  color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(s['title'] ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: deepBrown)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickMenu(BuildContext context, String title, String subtitle,
      IconData icon, Widget page) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryBlue, size: 32),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: deepBrown,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildWideMenu(BuildContext context, String title, String subtitle,
      IconData icon, Widget page) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: softPink.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: softPink, size: 24),
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
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class SaranKesanPage extends StatefulWidget {
  const SaranKesanPage({super.key});

  @override
  State<SaranKesanPage> createState() => _SaranKesanPageState();
}

class _SaranKesanPageState extends State<SaranKesanPage> {
  final TextEditingController _kesanCtrl = TextEditingController();
  final TextEditingController _pesanCtrl = TextEditingController();
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('saran_history');
    if (historyString != null) {
      final List<dynamic> decoded = jsonDecode(historyString);
      setState(() {
        _history = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveFeedback() async {
    if (_kesanCtrl.text.trim().isEmpty || _pesanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Harap lengkapi semua kolom yang tersedia.")),
      );
      return;
    }

    final newFeedback = {
      'kesan': _kesanCtrl.text.trim(),
      'pesan': _pesanCtrl.text.trim(),
      'date': DateTime.now().toString().substring(0, 16),
    };

    setState(() {
      _history.insert(0, newFeedback);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saran_history', jsonEncode(_history));

    _kesanCtrl.clear();
    _pesanCtrl.clear();
    FocusScope.of(context).unfocus();

    if (mounted) {
      NotifService.show(
        "Ulasan Terkirim 💌",
        "Terima kasih atas ulasan dan masukan yang kamu berikan!",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Ulasan Anda berhasil dikirim. Terima kasih!"),
            backgroundColor: primaryBlue),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Ulasan & Masukan",
            style: TextStyle(
                color: deepBrown,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Banner ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, softPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: softPink.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ]),
              child: Row(
                children: [
                  const Icon(Icons.volunteer_activism_rounded,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Bantu Kami Berkembang!",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        SizedBox(height: 5),
                        Text("Pendapatmu sangat berarti untuk AuraMusic.",
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- Form Ulasan ---
            const Text("Tulis Ulasan Anda",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: deepBrown)),
            const SizedBox(height: 15),
            _buildTextField(_kesanCtrl, "Pengalaman",
                "Bagaimana pengalaman Anda?", Icons.mood_rounded),
            const SizedBox(height: 15),
            _buildTextField(_pesanCtrl, "Saran / Laporan",
                "Ada fitur yang kurang atau error?", Icons.bug_report_rounded),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepBrown,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: deepBrown.withOpacity(0.3),
                ),
                onPressed: _saveFeedback,
                child: const Text("Kirim Ulasan",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 40),

            // --- Riwayat ---
            const Text("Riwayat Ulasan",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: deepBrown)),
            const SizedBox(height: 15),
            if (_history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded,
                          color: Colors.grey.shade300, size: 60),
                      const SizedBox(height: 10),
                      Text("Belum ada riwayat ulasan.",
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: softPink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text("Terkirim",
                                    style: TextStyle(
                                        color: softPink,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Text(item['date'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 15),
                          const Text("Pengalaman",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: primaryBlue)),
                          const SizedBox(height: 2),
                          Text(item['kesan'] ?? '',
                              style: const TextStyle(
                                  fontSize: 14, color: deepBrown)),
                          const SizedBox(height: 12),
                          const Text("Saran & Masukan",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: softPink)),
                          const SizedBox(height: 2),
                          Text(item['pesan'] ?? '',
                              style: const TextStyle(
                                  fontSize: 14, color: deepBrown)),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      maxLines: 4,
      minLines: 2,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }
}
