// ignore_for_file: unnecessary_const, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/widget_radio.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  final String streamUrl = "https://play-93fm.madiunkota.go.id/live";
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isBuffering = false; // tambahkan ini

  @override
  void initState() {
    super.initState();
    _initAudioSession();

    _preloadAudio().then((_) {
      // Auto play setelah preload selesai
      _playAudio();
    });
    _player.playerStateStream.listen((state) {
      final isActuallyPlaying = state.playing;
      bool isBuffering = state.processingState == ProcessingState.buffering;
      print('playing: $isActuallyPlaying, buffering: $isBuffering');
      if (mounted) {
        setState(() {
          _isPlaying = isActuallyPlaying;
          _isBuffering = isBuffering;
        });
      }
    });
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> _preloadAudio() async {
    try {
      await _player.setUrl(streamUrl);
    } catch (e) {
      print("Error loading stream: $e");
    }
  }

  Future<void> _playAudio() async {
    setState(() {
      _isBuffering = true;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tidak ada koneksi internet."),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        return;
      }

      await _player.play();
    } catch (e) {
      print("Gagal memutar audio: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memutar audio: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
      }
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _player.stop();
    } catch (e) {
      print("Gagal menghentikan audio: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        LiveBroadcastButton(
          isPlaying: _isPlaying,
          onPlay: _playAudio,
          onStop: _stopAudio,
        ),
        if (_isBuffering)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 255, 160, 0).withOpacity(0.3),
                      const Color(0xFF1E88E5).withOpacity(0.3),
                    ], // Merah ke biru
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular progress indicator in the center
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    // Text label with modern style
                    Positioned(
                      bottom: 10, // Adjust position of the text label
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "LPPL Radio",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            "Suara Madiun",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Sedang memuat siaran...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
