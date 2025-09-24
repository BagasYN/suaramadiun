import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  AudioPlayerWidget({
    Key? key,
    required this.player,
    required this.audioSamples,
    required this.isPlaying,
    required this.playAudio,
    required this.stopAudio,
  }) : super(key: key);

  final List<double> audioSamples;
  final bool isPlaying; // Tambahkan properti untuk status pemutaran audio
  final VoidCallback playAudio; // Tambahkan properti untuk metode playAudio
  final AudioPlayer player;
  final VoidCallback stopAudio; // Tambahkan properti untuk metode stopAudio

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;

  @override
  void dispose() {
    widget.player.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    widget.player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed ||
          playerState.processingState == ProcessingState.idle) {
        setState(() {
          _isPlaying = false;
        });
      } else if (playerState.processingState == ProcessingState.ready ||
          playerState.processingState == ProcessingState.buffering ||
          playerState.processingState == ProcessingState.ready) {
        setState(() {
          _isPlaying = true;
        });
      }
    });
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      widget.stopAudio(); // Stop audio if it's playing
      setState(() {
        _isPlaying = false; // Update playback status
      });
    } else {
      widget.playAudio(); // Start audio if it's not playing
      setState(() {
        _isPlaying = true; // Update playback status
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: GestureDetector(
        onTap: () {
          if (_isPlaying) {
            widget.player.stop(); // Stop audio if it's playing
          } else {
            widget.player.play(); // Start audio if it's not playing
          }
        },
        child: Card(
          elevation: 2,
          color: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/bannerlppl.png'), // Ganti dengan path gambar pattern Anda
                fit: BoxFit.fill,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        height: size.height * 0.1,
                        child: MaterialButton(
                          onPressed: () {
                            if (_isPlaying) {
                              widget.player
                                  .stop(); // Stop audio if it's playing
                            } else {
                              widget.player
                                  .play(); // Start audio if it's not playing
                            }
                          },
                          highlightColor:
                              Colors.transparent, // Menghilangkan highlight
                          splashColor: Colors.transparent,
                          child: Container(
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: _isPlaying
                                  ? Image.asset(
                                      'assets/images/pause.png', // Path ke ikon custom
                                      key: ValueKey("pause"),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover)
                                  : Image.asset(
                                      'assets/images/play.png', // Path ke ikon custom
                                      key: ValueKey("play"),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

