import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import '../services/deezer_service.dart';

const primaryBlue = Color(0xFF7DA7D9);
const softPink = Color(0xFFF7A6B8);
const bg = Color(0xFFF4F5F7);
const deepBrown = Color(0xFF5D4037);

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int _currentGameMode = 0;

  // --- STATE BLIND TEST AUDIO ---
  final AudioPlayer _player = AudioPlayer();
  bool _isLoadingGame1 = false;
  int _questionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool? _isCorrect;
  bool _isFinished = false;
  List<Map<String, dynamic>> _blindTestQuestions = [];
  bool _isAudioPaused = false;

  // --- STATE NEON DRUM PAD ---
  int _tapCount = 0;
  int _timeLeft = 10;
  bool _isGameRunning = false;
  Timer? _timer;
  bool _isPadPressed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  // ==================== LOGIKA BLIND TEST ====================
  Future<void> _initBlindTest() async {
    setState(() {
      _isLoadingGame1 = true;
      _questionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _isCorrect = null;
      _isFinished = false;
      _isAudioPaused = false;
    });

    try {
      // Mengambil lagu dari artis yang direquest
      var raw1 = await searchMusic("One Direction");
      var raw2 = await searchMusic("Justin Bieber");
      var raw3 = await searchMusic("Bruno Mars");

      var rawSongs = [...raw1, ...raw2, ...raw3];
      var songs = rawSongs
          .where(
              (s) => s['preview'] != null && s['preview'].toString().isNotEmpty)
          .toList();

      if (songs.length < 10) {
        var fallback = await searchMusic("2010s Pop Hits");
        songs.addAll(fallback.where(
            (s) => s['preview'] != null && s['preview'].toString().isNotEmpty));
      }

      // Filter Anti-Duplikat: Hindari lagu dengan judul yang sama (misal versi cover/akustik)
      var uniqueSongs = <String, Map<String, dynamic>>{};
      for (var s in songs) {
        uniqueSongs[s['title']] = s;
      }
      songs = uniqueSongs.values.toList();
      songs.shuffle();

      List<Map<String, dynamic>> questions = [];
      for (int i = 0; i < min(10, songs.length); i++) {
        var correctSong = songs[i];
        List<String> options = [correctSong['title']];

        var wrongSongs =
            songs.where((s) => s['title'] != correctSong['title']).toList();
        wrongSongs.shuffle();

        for (int j = 0; j < 3 && j < wrongSongs.length; j++) {
          options.add(wrongSongs[j]['title']);
        }
        options.shuffle();

        questions.add({
          "preview": correctSong['preview'],
          "correct": correctSong['title'],
          "options": options,
        });
      }

      if (mounted) {
        setState(() {
          _blindTestQuestions = questions;
          _isLoadingGame1 = false;
        });
        _playPreview();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGame1 = false);
        // Munculkan variabel "e" untuk melihat error aslinya di HP jika masih gagal
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal memuat lagu: $e")));
      }
    }
  }

  void _playPreview() async {
    if (_questionIndex < _blindTestQuestions.length) {
      String url = _blindTestQuestions[_questionIndex]['preview'];
      await _player.play(UrlSource(url));
      if (mounted) setState(() => _isAudioPaused = false);
    }
  }

  // ==================== LOGIKA NEON DRUM ====================
  void _startTapGame() {
    setState(() {
      _tapCount = 0;
      _timeLeft = 10;
      _isGameRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          setState(() => _isGameRunning = false);
          timer.cancel();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: _currentGameMode != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
                onPressed: () {
                  setState(() => _currentGameMode = 0);
                  _timer?.cancel();
                  _player.stop();
                },
              )
            : null,
        title: Text(
            _currentGameMode == 0
                ? "ARCADE MODE"
                : (_currentGameMode == 1 ? "BLIND TEST" : "NEON DRUM PAD"),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: primaryBlue,
        elevation: 0,
      ),
      body: _buildCurrentGame(),
    );
  }

  Widget _buildCurrentGame() {
    if (_currentGameMode == 0) return _buildMenu();
    if (_currentGameMode == 1) return _buildTebakLaguContent();
    return _buildTapTapContent();
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pilih Mode Game",
              style: TextStyle(
                  color: deepBrown, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text(
              "Latih pengetahuan musik dan kecepatan jarimu dengan game interaktif ini.",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 40),
          _menuCard(
              "Blind Test Hits",
              "Tebak lagu dari audio Deezer (Membutuhkan Kuota)",
              Icons.headphones_rounded, () {
            setState(() => _currentGameMode = 1);
            _initBlindTest();
          }),
          const SizedBox(height: 20),
          _menuCard(
              "Neon Drum Pad",
              "Adu cepat jari di atas bantalan drum neon!",
              Icons.vibration_rounded,
              () => setState(() => _currentGameMode = 2)),
        ],
      ),
    );
  }

  Widget _menuCard(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: softPink.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: softPink, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: deepBrown,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey)
        ]),
      ),
    );
  }

  Widget _buildTebakLaguContent() {
    if (_isLoadingGame1) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }
    if (_blindTestQuestions.isEmpty) {
      return const Center(child: Text("Gagal memuat lagu. Coba lagi."));
    }
    if (_isFinished) return _buildScoreBoard();

    final q = _blindTestQuestions[_questionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text("TRACK ${_questionIndex + 1}/10",
                  style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: softPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text("SCORE: $_score",
                  style: const TextStyle(
                      color: softPink,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // Animasi Gelombang Audio
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryBlue.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ]),
          child: Icon(
              _selectedAnswer == null
                  ? Icons.graphic_eq_rounded
                  : Icons.music_note_rounded,
              size: 80,
              color: primaryBlue),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedAnswer == null)
              IconButton(
                icon: Icon(
                  _isAudioPaused
                      ? Icons.play_circle_fill_rounded
                      : Icons.pause_circle_filled_rounded,
                  color: primaryBlue,
                  size: 32,
                ),
                onPressed: () async {
                  if (_isAudioPaused) {
                    await _player.resume();
                    setState(() => _isAudioPaused = false);
                  } else {
                    await _player.pause();
                    setState(() => _isAudioPaused = true);
                  }
                },
              ),
            Text(
              _selectedAnswer == null
                  ? (_isAudioPaused ? "Audio Dipause" : "Mendengarkan Audio...")
                  : "Audio Dihentikan",
              style: const TextStyle(
                  color: deepBrown, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),

        const SizedBox(height: 30),
        ...q['options'].map<Widget>((opt) {
          bool isSel = _selectedAnswer == opt;
          Color btnColor = Colors.white;
          Color textColor = deepBrown;
          Color borderColor = Colors.transparent;

          if (isSel) {
            if (_isCorrect!) {
              btnColor = const Color(0xFFE8F5E9);
              borderColor = Colors.green;
              textColor = Colors.green;
            } else {
              btnColor = const Color(0xFFFFEBEE);
              borderColor = Colors.red;
              textColor = Colors.red;
            }
          } else if (_isCorrect != null && opt == q['correct']) {
            // Tampilkan jawaban benar jika user salah jawab
            btnColor = const Color(0xFFE8F5E9);
            borderColor = Colors.green.withOpacity(0.5);
            textColor = Colors.green;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () async {
                if (_isCorrect != null) return;
                await _player.stop(); // Hentikan audio saat memilih
                setState(() {
                  _selectedAnswer = opt;
                  _isCorrect = opt == q['correct'];
                  if (_isCorrect!) _score += 10;
                });
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                    color: btnColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 5,
                          offset: const Offset(0, 3))
                    ]),
                child: Center(
                  child: Text(opt,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        if (_isCorrect != null)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => setState(() {
                if (_questionIndex < 9) {
                  _questionIndex++;
                  _selectedAnswer = null;
                  _isCorrect = null;
                  _playPreview(); // Mainkan soal berikutnya
                } else {
                  _isFinished = true;
                }
              }),
              child: const Text("NEXT TRACK",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
          ),
      ]),
    );
  }

  Widget _buildTapTapContent() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              const Text("TIME LEFT",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("${_timeLeft}s",
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: _timeLeft <= 3 ? Colors.redAccent : deepBrown)),
            ],
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Column(
            children: [
              const Text("BEAT COUNT",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("$_tapCount",
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: primaryBlue)),
            ],
          ),
        ],
      ),
      const SizedBox(height: 60),

      // Tombol Drum Pad Berpijar
      GestureDetector(
        onTapDown: (_) {
          if (_isGameRunning) {
            setState(() {
              _tapCount++;
              _isPadPressed = true;
            });
          }
        },
        onTapUp: (_) => setState(() => _isPadPressed = false),
        onTapCancel: () => setState(() => _isPadPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          width: _isPadPressed ? 190 : 210,
          height: _isPadPressed ? 190 : 210,
          decoration: BoxDecoration(
            color: _isGameRunning ? softPink : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
                color: _isGameRunning ? softPink : Colors.white24, width: 4),
            boxShadow: [
              BoxShadow(
                  color: _isGameRunning
                      ? softPink.withOpacity(0.6)
                      : Colors.black12,
                  blurRadius: _isPadPressed ? 10 : 40,
                  spreadRadius: _isPadPressed ? 2 : 10)
            ],
          ),
          child: Center(
              child: Text(_isGameRunning ? "TAP!" : "READY",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: _isGameRunning ? Colors.white : Colors.grey))),
        ),
      ),
      const SizedBox(height: 80),

      if (!_isGameRunning && _timeLeft == 10)
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _startTapGame,
            child: const Text("START BEAT",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1))),

      if (!_isGameRunning && _timeLeft == 0)
        Column(
          children: [
            const Text("TIMES UP!",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => setState(() {
                      _timeLeft = 10;
                      _tapCount = 0;
                    }),
                child: const Text("TRY AGAIN",
                    style: TextStyle(
                        color: deepBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.bold))),
          ],
        )
    ]);
  }

  Widget _buildScoreBoard() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
              _currentGameMode == 1
                  ? Icons.stars_rounded
                  : Icons.flash_on_rounded,
              color: Colors.amber,
              size: 70),
          const SizedBox(height: 20),
          const Text("FINAL SCORE",
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("${_currentGameMode == 1 ? _score : _tapCount}",
              style: const TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue)),
          if (_currentGameMode == 2)
            Text(
                _tapCount > 60 ? "Dewa Drummer! 🥁" : "Penyanyi Kamar Mandi 🚿",
                style: const TextStyle(
                    color: softPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  if (_currentGameMode == 1) _initBlindTest();
                  if (_currentGameMode == 2) _startTapGame();
                },
                child: const Text("PLAY AGAIN",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 15),
          TextButton(
              onPressed: () => setState(() {
                    _currentGameMode = 0;
                    _timer?.cancel();
                    _player.stop();
                  }),
              child: const Text("BACK TO MENU",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }
}
