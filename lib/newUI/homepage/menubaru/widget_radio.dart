import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:marquee/marquee.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/home3.dart';

class LiveBroadcastButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  const LiveBroadcastButton({
    super.key,
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
  });

  @override
  State<LiveBroadcastButton> createState() => _LiveBroadcastButtonState();
}

class _LiveBroadcastButtonState extends State<LiveBroadcastButton> {
  String _nowPlayingTitle = '';
  late Timer _timerPlaying;
  late Timer _eqTimer;
  List<double> _eqHeights = [10, 20, 14, 24];
  final Random _random = Random();

  Future<void> fetchNowPlayingTitle() async {
    try {
      final response = await http
          .get(Uri.parse('https://play-93fm.madiunkota.go.id/status-json.xsl'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final source = data['icestats']['source'];
        String title;
        if (source is List && source.length > 1) {
          title = source[1]?['title'] ?? 'Live Broadcast';
        } else if (source is Map) {
          title = source['title'] ?? 'Live Broadcast';
        } else {
          title = 'Live Broadcast';
        }
        setState(() {
          _nowPlayingTitle = title;
        });
      }
    } catch (e) {
      debugPrint("Error fetch title: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNowPlayingTitle();
    _timerPlaying = Timer.periodic(const Duration(seconds: 40), (_) {
      fetchNowPlayingTitle();
    });
    _eqTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (widget.isPlaying) {
        setState(() {
          _eqHeights =
              List.generate(4, (index) => 8 + _random.nextInt(24).toDouble());
        });
      }
    });
  }

  @override
  void dispose() {
    _timerPlaying.cancel();
    _eqTimer.cancel();
    super.dispose();
  }

  void _openFullPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FullPlayerPage(
          nowPlayingTitle: _nowPlayingTitle,
          isPlaying: widget.isPlaying,
          onPlay: widget.onPlay,
          onStop: widget.onStop,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _openFullPlayer,
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! < -10) {
          _openFullPlayer(); // swipe up buka full player
        }
      },
      onDoubleTap: () {
        HapticFeedback.mediumImpact();
        widget.isPlaying ? widget.onStop() : widget.onPlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF21487A), Color(0xFF163657)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            /// Equalizer / Radio Icon
            Hero(
              tag: "playerEqualizer",
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: widget.isPlaying
                      ? Row(
                    key: const ValueKey("eq"),
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_eqHeights.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: 4,
                        height: _eqHeights[index],
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.amber.shade200],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: _eqHeights[index] / 4,
                              spreadRadius: 1,
                            )
                          ],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  )
                      : const Icon(Icons.radio,
                      key: ValueKey("icon"),
                      color: Colors.white,
                      size: 24),
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// Now Playing Text with shimmer while loading
            Expanded(
              child: SizedBox(
                height: 24,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _nowPlayingTitle.isNotEmpty
                      ? Marquee(
                    key: ValueKey(_nowPlayingTitle),
                    text: _nowPlayingTitle,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade400,
                    ),
                    blankSpace: 40,
                    velocity: 35,
                    fadingEdgeStartFraction: 0.1,
                    fadingEdgeEndFraction: 0.1,
                  )
                      : Shimmer.fromColors(
                    key: const ValueKey("loading"),
                    baseColor: Colors.grey.shade700,
                    highlightColor: Colors.grey.shade400,
                    child: Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// Play / Stop Button
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.isPlaying) {
                  widget.onStop();
                } else {
                  widget.onPlay();
                }
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.isPlaying
                        ? "Stop Radio"
                        : "Play Radio"),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Hero(
                tag: "playerButton",
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: widget.isPlaying ? 1.05 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.isPlaying
                          ? const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : LinearGradient(
                        colors: [Colors.green, Colors.lightGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isPlaying
                              ? Colors.red.withOpacity(0.4)
                              : Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Icon(
                      widget.isPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
