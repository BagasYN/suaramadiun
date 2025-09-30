import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';


const String listenersUrl = 'https://play-93fm.madiunkota.go.id/status-json.xsl';

class FullPlayerPage extends StatefulWidget {
  final String nowPlayingTitle;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onStop;
  final String? artworkAsset;

  const FullPlayerPage({
    super.key,
    required this.nowPlayingTitle,
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
    this.artworkAsset,
  });

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage>
    with TickerProviderStateMixin {
  late AnimationController _btnController;
  late Animation<double> _scaleAnim;
  late AnimationController _rotateController;
  late SiriWaveController _waveController;
  late AnimationController _glowController;
  late AnimationController _needleController;

  int _listeners = 0;
  late Timer _listenersTimer;
  bool _localPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _localPlaying = widget.isPlaying;

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeInOut),
    );

    _rotateController =
        AnimationController(vsync: this, duration: const Duration(seconds: 14));
    if (_localPlaying) _rotateController.repeat();

    _waveController = SiriWaveController();
    _waveController.setAmplitude(_localPlaying ? 1.0 : 0.0);

    _glowController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (_localPlaying) {
      _needleController.forward();
    }

    _fetchListenersCount();
    _listenersTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _fetchListenersCount());
  }

  @override
  void didUpdateWidget(covariant FullPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != _localPlaying) {
      _localPlaying = widget.isPlaying;
      _updatePlayState(_localPlaying);
    }
  }

  @override
  void dispose() {
    _listenersTimer.cancel();
    _btnController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    _needleController.dispose();
    super.dispose();
  }

  void _updatePlayState(bool playing) {
    if (playing) {
      _rotateController.repeat();
      _waveController.setAmplitude(1.0);
      _needleController.forward();
    } else {
      _rotateController.stop();
      _waveController.setAmplitude(0.0);
      _needleController.reverse();
    }
  }

  Future<void> _fetchListenersCount() async {
    try {
      final resp = await http.get(Uri.parse(listenersUrl));
      if (resp.statusCode == 200) {
        final jsonBody = jsonDecode(resp.body);
        int listeners = 0;
        try {
          final sources = jsonBody['icestats']?['source'];
          if (sources is List && sources.isNotEmpty) {
            listeners = sources[0]['listeners'] ?? 0;
          } else if (sources is Map) {
            listeners = sources['listeners'] ?? 0;
          }
        } catch (_) {}
        setState(() {
          _listeners = listeners;
          _hasError = false;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (_) {
      setState(() => _hasError = true);
    }
  }

  void _onPlayPausePressed() {
    HapticFeedback.lightImpact();
    if (_localPlaying) {
      widget.onStop();
      _localPlaying = false;
    } else {
      widget.onPlay();
      _localPlaying = true;
    }
    _updatePlayState(_localPlaying);
    setState(() {});
  }

  void _onShare() {
    final textToShare =
        "Sedang mendengarkan 93 FM Madiun 🎶\n\n"
        "Lagu: ${widget.nowPlayingTitle.isNotEmpty ? widget.nowPlayingTitle : '-'}\n\n"
        "Klik untuk dengarkan live Radio Suara MAdiun:\nhttps://play.google.com/store/apps/details?id=com.kominfo.lppl_93fm_suara_madiun";
    Share.share(textToShare, subject: "Live Streaming 93 FM Madiun");
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    const bgColor = Color(0xFF21487A);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 600) {
          Navigator.of(context).maybePop();
        }
      },
      onDoubleTap: _onPlayPausePressed,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Now Playing',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _onShare,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 500),
                    scale: _listeners > 0 ? 1.1 : 1.0,
                    child: const Icon(Icons.wifi_tethering,
                        color: Color(0xFFFFC107)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_listeners',
                    style: const TextStyle(
                        color: Color(0xFFFFC107), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 28),

              // VINYL + NEEDLE
              Center(
                child: AnimatedBuilder(
                  animation:
                  Listenable.merge([_rotateController, _glowController]),
                  builder: (context, child) {
                    final glow = (0.6 + 0.4 * _glowController.value);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: _localPlaying
                                ? [
                              BoxShadow(
                                color: Colors.amber,
                                blurRadius: 40 * glow,
                                spreadRadius: 8 * glow,
                              )
                            ]
                                : [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Transform.rotate(
                            angle: _rotateController.value * 2 * pi,
                            child: child,
                          ),
                        ),

                        // Needle
                        Positioned(
                          top: 0,
                          right: screenW * 0.15,
                          child: AnimatedBuilder(
                            animation: _needleController,
                            builder: (context, _) {
                              double angle =
                              lerpDouble(-0.5, 0.2, _needleController.value)!;
                              return Transform.rotate(
                                angle: angle,
                                alignment: Alignment.topLeft,
                                child: Container(
                                  width: 100,
                                  height: 8,
                                  color: Colors.grey.shade300,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  child: Container(
                    width: screenW * 0.65,
                    height: screenW * 0.65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      gradient: const RadialGradient(
                        colors: [Colors.black87, Colors.black],
                        radius: 0.9,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Grooves
                        for (int i = 1; i <= 12; i++)
                          Container(
                            width: screenW * 0.65 - (i * 6),
                            height: screenW * 0.65 - (i * 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.black),
                            ),
                          ),

                        // Label
                        Container(
                          width: screenW * 0.28,
                          height: screenW * 0.28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: widget.artworkAsset != null
                              ? ClipOval(
                            child: Image.asset(
                              widget.artworkAsset!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : const Center(
                              child: Icon(Icons.radio,
                                  size: 60, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Live Radio',
                style: TextStyle(
                    color: Color(0xFFFFD88C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 36,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Marquee(
                    text: widget.nowPlayingTitle.isNotEmpty
                        ? widget.nowPlayingTitle
                        : '-',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    blankSpace: 60,
                    velocity: 30,
                    fadingEdgeStartFraction: 0.12,
                    fadingEdgeEndFraction: 0.12,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_hasError)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "⚠️ Tidak dapat memuat data streaming.\nPeriksa koneksi Anda.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                )
              else
                SizedBox(
                  height: 110,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: SiriWave(
                      controller: _waveController,
                      style: SiriWaveStyle.ios_9,
                      options: SiriWaveOptions(
                        height: 80,
                        width: MediaQuery.of(context).size.width - 44,
                        showSupportBar: true,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),

              const Spacer(),

              GestureDetector(
                onTapDown: (_) => _btnController.forward(),
                onTapUp: (_) {
                  _btnController.reverse();
                  _onPlayPausePressed();
                },
                onTapCancel: () => _btnController.reverse(),
                onLongPress: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Detail fitur coming soon"),
                  ));
                },
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Container(
                      key: ValueKey(_localPlaying),
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        _localPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 68,
                        color: bgColor,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 34),
            ],
          ),
        ),
      ),
    );
  }
}
