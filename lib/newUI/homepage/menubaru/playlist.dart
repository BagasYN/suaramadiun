import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/playlistvideo.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> playlists = [];
  bool isLoading = true;
  static String youtubeApiKey = "";
  static String youtubeChannelId = "";
  late Timer _timer;

  String? selectedPlaylistId;
  String? selectedPlaylistTitle;

  late final AnimationController _fadeController;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  final int itemsPerPage = 5;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    fetchFirebaseAndPlaylists();
    _timer = Timer.periodic(const Duration(seconds: 40), (_) => fetchFirebaseAndPlaylists());
  }

  Future<void> fetchFirebaseAndPlaylists() async {
    try {
      final data = await http.get(Uri.parse(
          'https://live--suara-madiun-default-rtdb.firebaseio.com/.json'));
      if (data.statusCode == 200) {
        final jsonData = jsonDecode(data.body);
        final key = jsonData['youtubeApiKey'];
        final channel = jsonData['youtubeChannelId'];
        if (key != null &&
            channel != null &&
            (key != youtubeApiKey || channel != youtubeChannelId)) {
          youtubeApiKey = key;
          youtubeChannelId = channel;
          await fetchYouTubePlaylists();
        }
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchYouTubePlaylists() async {
    if (youtubeApiKey.isEmpty || youtubeChannelId.isEmpty) return;
    List<Map<String, dynamic>> allPlaylists = [];
    String? nextPageToken;

    try {
      do {
        final url =
            'https://www.googleapis.com/youtube/v3/playlists?part=snippet,contentDetails&channelId=$youtubeChannelId&maxResults=50&pageToken=${nextPageToken ?? ''}&key=$youtubeApiKey';
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final items = data['items'] ?? [];
          allPlaylists.addAll(List<Map<String, dynamic>>.from(items.map((item) => {
            'title': item['snippet']['title'],
            'thumbnail': item['snippet']['thumbnails']['high']['url'],
            'videoCount': item['contentDetails']['itemCount'],
            'playlistId': item['id'],
          })));
          nextPageToken = data['nextPageToken'];
        } else {
          throw Exception('Failed to load playlists');
        }
      } while (nextPageToken != null);

      setState(() {
        playlists = allPlaylists;
        isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      debugPrint('Error fetching playlists: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedPlaylistId != null && selectedPlaylistTitle != null) {
      return PlaylistVideoListPage(
        playlistId: selectedPlaylistId!,
        playlistTitle: selectedPlaylistTitle!,
        youtubeApiKey: youtubeApiKey,
        onBack: () => setState(() {
          selectedPlaylistId = null;
          selectedPlaylistTitle = null;
        }),
      );
    }

    final totalPages = (playlists.length / itemsPerPage).ceil();

    return SafeArea(
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(12),
        child: RefreshIndicator(
          onRefresh: fetchFirebaseAndPlaylists,
          child: isLoading
              ? ListView.builder(
            itemCount: 2,
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[700]!,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          )
              : Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: totalPages,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _scrollController.jumpTo(0); // Reset scroll tiap page
                  },
                  itemBuilder: (context, pageIndex) {
                    final startIndex = pageIndex * itemsPerPage;
                    final endIndex =
                    (startIndex + itemsPerPage).clamp(0, playlists.length);
                    final currentItems = playlists.sublist(startIndex, endIndex);

                    return Scrollbar(
                      thumbVisibility: true,
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: currentItems.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (_, index) {
                          final p = currentItems[index];
                          return FadeTransition(
                            opacity: _fadeController,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedPlaylistId = p['playlistId'];
                                  selectedPlaylistTitle = p['title'];
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: p['thumbnail'],
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                              color: Colors.grey[900],
                                              height: 200,
                                            ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['title'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${p['videoCount']} videos',
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13),
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
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Tombol Prev / Next
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _currentPage > 0
                        ? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                        : null,
                    label: const Text("Prev", style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _currentPage < totalPages - 1
                        ? () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                        : null,
                    label: const Text("Next", style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SmoothPageIndicator(
                controller: _pageController,
                count: totalPages,
                effect: const WormEffect(
                  activeDotColor: Colors.white,
                  dotColor: Colors.grey,
                  dotHeight: 6,
                  dotWidth: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
