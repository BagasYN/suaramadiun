//playlistvideo.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/bottom_navigation.dart';


class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final String channelTitle;
  final List<Map<String, dynamic>> playlistVideos;

  const VideoPlayerPage({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.channelTitle,
    required this.playlistVideos,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final YoutubePlayerController _controller;
  late String _currentVideoId;
  late String _currentVideoTitle;
  late String _currentChannelTitle;

  @override
  void initState() {
    super.initState();
    _currentVideoId = widget.videoId;
    _currentVideoTitle = widget.videoTitle;
    _currentChannelTitle = widget.channelTitle;

    _controller = YoutubePlayerController(
      initialVideoId: _currentVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        forceHD: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant VideoPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _currentVideoId = widget.videoId;
      _currentVideoTitle = widget.videoTitle;
      _currentChannelTitle = widget.channelTitle;
      _controller.load(_currentVideoId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playVideo(String videoId, String videoTitle, String channelTitle) {
    setState(() {
      _currentVideoId = videoId;
      _currentVideoTitle = videoTitle;
      _currentChannelTitle = channelTitle;
    });
    _controller.load(videoId);
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.amber,
        progressColors: const ProgressBarColors(
          playedColor: Colors.amber,
          handleColor: Colors.amberAccent,
        ),
        onReady: () {
          debugPrint('Player is ready.');
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,

          // ⭐ NAVBAR DITAMBAHKAN DI SINI
          //bottomNavigationBar: BottomNavBar(
          // selectedIndex: 2,
          // onItemTapped: (index) {},
          //),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/img/bglppl.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              SafeArea(
                child: Column(
                  children: [

                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF21487A),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Text(
                              _currentVideoTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.black87,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (context) => SizedBox(
                                  height: 200,
                                  child: Column(
                                    children: const [
                                      SizedBox(height: 12),
                                      Text(
                                        "Menu",
                                        style: TextStyle(color: Colors.white, fontSize: 18),
                                      ),
                                      Divider(color: Colors.white24),
                                      ListTile(
                                        leading: Icon(Icons.share, color: Colors.white),
                                        title: Text("Bagikan", style: TextStyle(color: Colors.white)),
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.flag, color: Colors.white),
                                        title: Text("Laporkan", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Konten Video dan Playlist
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: player,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentVideoTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8.0,
                                    color: Colors.black54,
                                    offset: Offset(2.0, 2.0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentChannelTitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white54),
                            const Text(
                              "Berikutnya",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: _buildPlaylistView(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylistView() {
    final otherVideos = widget.playlistVideos
        .where((v) => v['videoId'] != _currentVideoId)
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: otherVideos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final video = otherVideos[index];
        return GestureDetector(
          onTap: () => _playVideo(
              video['videoId'], video['title'], video['channelTitle']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Image.network(
                    video['thumbnail'],
                    width: 120,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 80,
                      color: Colors.grey,
                      child: const Icon(Icons.broken_image, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Text(
                      video['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class PlaylistVideoListPage extends StatefulWidget {
  final String playlistId;
  final String playlistTitle;
  final String youtubeApiKey;
  final VoidCallback? onBack;

  const PlaylistVideoListPage({
    super.key,
    required this.playlistId,
    required this.playlistTitle,
    required this.youtubeApiKey,
    this.onBack,
  });

  @override
  State<PlaylistVideoListPage> createState() => _PlaylistVideoListPageState();
}

class _PlaylistVideoListPageState extends State<PlaylistVideoListPage> {
  List<Map<String, dynamic>> videos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlaylistVideos();
  }

  Future<void> fetchPlaylistVideos() async {
    String baseUrl =
        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=${widget
        .playlistId}&maxResults=50&key=${widget.youtubeApiKey}';

    List<Map<String, dynamic>> allVideos = [];
    String? nextPageToken;

    try {
      do {
        final url = nextPageToken == null
            ? baseUrl
            : '$baseUrl&pageToken=$nextPageToken';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['items'] != null) {
            allVideos.addAll(
              List<Map<String, dynamic>>.from(data['items'].map((item) {
                final thumbnails = item['snippet']['thumbnails'];
                final thumbnailUrl = thumbnails != null &&
                    thumbnails['medium'] != null
                    ? thumbnails['medium']['url']
                    : 'https://i.ytimg.com/vi/${item['snippet']['resourceId']['videoId']}/mqdefault.jpg';

                return {
                  'title': item['snippet']['title'],
                  'thumbnail': thumbnailUrl,
                  'videoId': item['snippet']['resourceId']['videoId'],
                  'channelTitle': item['snippet']['videoOwnerChannelTitle'] ??
                      'Nama Channel Tidak Tersedia',
                };
              })),
            );
          }
          nextPageToken = data['nextPageToken'];
        } else {
          throw Exception('Failed to fetch videos');
        }
      } while (nextPageToken != null);

      setState(() {
        videos =
            allVideos
                .where((v) => v['title'].toLowerCase() != 'private video')
                .toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paddingHorizontal = MediaQuery
        .of(context)
        .size
        .width * 0.04;

    return SafeArea(

      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: 14,
              horizontal: paddingHorizontal,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

            decoration: BoxDecoration(
              color: const Color(0xFF21487A),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),

            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.playlistTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
                : Padding(
              padding:
              EdgeInsets.symmetric(horizontal: paddingHorizontal),
              child: ListView.separated(
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VideoPlayerPage(
                                videoId: video['videoId'],
                                videoTitle: video['title'],
                                channelTitle: video['channelTitle'],
                                playlistVideos: videos,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: Image.network(
                              video['thumbnail'],
                              width: 120,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 80,
                                  color: Colors.grey,
                                  child: const Icon(
                                      Icons.broken_image, color: Colors.white),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              child: Text(
                                video['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}