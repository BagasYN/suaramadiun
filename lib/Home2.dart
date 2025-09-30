// home2.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:lppl_93fm_suara_madiun/newUI/constants/constant.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/bottom_navigation.dart';
import 'package:lppl_93fm_suara_madiun/newUI/radioscreen.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/playlistvideo.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/playlist.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  // === API endpoint ===
  static const instagramFeedUrl =
      'https://rss.app/feeds/v1.1/oBYCZ1GV2crnFf21.json';
  static const kabarWargaUrl =
      'https://kominfo.madiunkota.go.id/api/berita/getKabarWarga';

  // === Data ===
  List<Map<String, dynamic>> _instagramPosts = [];
  List<Map<String, dynamic>> _kabarWarga = [];
  List<Map<String, dynamic>> _madiunTodayPosts = [];

  bool _isLoadingPosts = false;
  String profileLink = "";
  int _selectedIndex = 0;

  // === Playlist ===
  List<Map<String, dynamic>> playlists = [];
  bool isLoadingPlaylist = true;
  static String youtubeApiKey = "";
  static String youtubeChannelId = "";
  Timer? _timerPlaying;
  String? selectedPlaylistId;
  String? selectedPlaylistTitle;

  // === Pagination berita ===
  int _currentPage = 1;
  final int _perPage = 8;

  @override
  void initState() {
    super.initState();
    _loadAllPosts();
    _fetchDataAndUpdateVariablesFromFirebase();

    // Auto refresh 40 dtik
    _timerPlaying = Timer.periodic(const Duration(seconds: 40), (timer) async {
      final data = await _fetchDataFromFirebase();
      final firebaseYoutubeApiKey = data['youtubeApiKey'];
      final firebaseYoutubeChannelId = data['youtubeChannelId'];

      if (firebaseYoutubeApiKey != null &&
          firebaseYoutubeChannelId != null &&
          (firebaseYoutubeApiKey != youtubeApiKey ||
              firebaseYoutubeChannelId != youtubeChannelId)) {
        youtubeApiKey = firebaseYoutubeApiKey;
        youtubeChannelId = firebaseYoutubeChannelId;
        await _fetchYouTubePlaylists();
      }
    });
  }

  @override
  void dispose() {
    _timerPlaying?.cancel();
    super.dispose();
  }


  Future<Map<String, dynamic>> _fetchDataFromFirebase() async {
    try {
      final response = await http.get(Uri.parse(
          'https://live--suara-madiun-default-rtdb.firebaseio.com/.json'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch data from Firebase');
      }
    } catch (error) {
      debugPrint('Error fetching data from Firebase: $error');
      return {};
    }
  }

  Future<void> _fetchDataAndUpdateVariablesFromFirebase() async {
    try {
      final data = await _fetchDataFromFirebase();
      final firebaseYoutubeApiKey = data['youtubeApiKey'];
      final firebaseYoutubeChannelId = data['youtubeChannelId'];

      if (firebaseYoutubeApiKey != null && firebaseYoutubeChannelId != null) {
        youtubeApiKey = firebaseYoutubeApiKey;
        youtubeChannelId = firebaseYoutubeChannelId;
        await _fetchYouTubePlaylists();
      }
    } catch (error) {
      debugPrint('Error fetching data from Firebase: $error');
    }
  }

  Future<void> _fetchYouTubePlaylists() async {
    if (youtubeApiKey.isEmpty || youtubeChannelId.isEmpty) {
      setState(() => isLoadingPlaylist = false);
      return;
    }

    List<Map<String, dynamic>> allPlaylists = [];
    String? nextPageToken;

    try {
      do {
        final url =
            'https://www.googleapis.com/youtube/v3/playlists?part=snippet,contentDetails&channelId=$youtubeChannelId&maxResults=50&pageToken=${nextPageToken ??
            ''}&key=$youtubeApiKey';

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final items = data['items'] ?? [];
          allPlaylists.addAll(List<Map<String, dynamic>>.from(items.map((item) {
            return {
              'title': item['snippet']['title'],
              'thumbnail': item['snippet']['thumbnails']['medium']['url'],
              'videoCount': item['contentDetails']['itemCount'],
              'playlistId': item['id'],
            };
          })));

          nextPageToken = data['nextPageToken'];
        } else {
          throw Exception('Gagal memuat playlist');
        }
      } while (nextPageToken != null);

      setState(() {
        playlists = allPlaylists;
        isLoadingPlaylist = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoadingPlaylist = false);
    }
  }

  Future<void> _loadAllPosts() async {
    setState(() => _isLoadingPosts = true);
    final instagramData = await _fetchInstagramPosts();
    if (mounted) setState(() => _instagramPosts = instagramData);

    await _fetchKabarWargaAPI();
    await _fetchMadiunTodayAPI();

    if (mounted) setState(() => _isLoadingPosts = false);
  }

  Future<List<Map<String, dynamic>>> _fetchInstagramPosts() async {
    try {
      final response = await http.get(Uri.parse(instagramFeedUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        profileLink = data['home_page_url'] ?? "";

        return (data['items'] as List)
            .map<Map<String, dynamic>>((post) =>
        {
          'title': post['title'],
          'url': post['url'],
          'image': (post['attachments'] != null &&
              post['attachments'].isNotEmpty)
              ? post['attachments'][0]['url']
              : null,
        })
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching Instagram posts: $e');
    }
    return [];
  }

  Future<void> _fetchKabarWargaAPI() async {
    try {
      final response = await http.post(
        Uri.parse(kabarWargaUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password1,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body)['data'] as List;
        final posts = data.reversed
            .map((item) =>
        {
          'title': item['judul'],
          'url': item['link'],
          'image': item['gambar'],
        })
            .toList();
        if (mounted) setState(() => _kabarWarga = posts);
      }
    } catch (e) {
      debugPrint('Error fetching Kabar Warga: $e');
    }
  }

  Future<void> _fetchMadiunTodayAPI() async {
    try {
      final response = await http.post(
        Uri.parse('https://MadiunToday.id/api/berita/semua'),
        headers: {
          'passcode': passcode2,
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body)['data'] as List;
        final posts = data
            .map((item) =>
        {
          'title': item['slug'] ?? 'No Title',
          'url': item['link'] ?? 'No link',
          'image': item['thumbnail'] ?? '',
        })
            .toList();
        if (mounted) setState(() => _madiunTodayPosts = posts);
      }
    } catch (e) {
      debugPrint('Error fetching MadiunToday: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
                const SizedBox(height: 8),
                const RadioScreen(),

                // animasiswitcher tab
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _getSelectedPage(),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey(0),
          child: _buildSpotifyStyleHome(),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey(1),
          child: _buildAllNewsPage(),
        );
      case 2:
        return KeyedSubtree(
          key: ValueKey(2),
          child: PlaylistPage(),
        );
      default:
        return KeyedSubtree(
          key: const ValueKey(0),
          child: _buildSpotifyStyleHome(),
        );
    }
  }

  Widget _buildSpotifyStyleHome() {
    if (selectedPlaylistId != null && selectedPlaylistTitle != null) {
      return PlaylistVideoListPage(
        playlistId: selectedPlaylistId!,
        playlistTitle: selectedPlaylistTitle!,
        youtubeApiKey: youtubeApiKey,
        onBack: () {
          setState(() {
            selectedPlaylistId = null;
            selectedPlaylistTitle = null;
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchDataAndUpdateVariablesFromFirebase();
        await _loadAllPosts();
      },
      color: Colors.white,
      backgroundColor: Colors.blueAccent,
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Selamat Datang",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildPlaylistSection(),
            const SizedBox(height: 20),
            _buildAutoCarouselSection("Kabar Warga", _kabarWarga),
            const SizedBox(height: 20),
            _buildAutoCarouselSection("Instagram Feed", _instagramPosts),
            const SizedBox(height: 20),
            _buildAutoCarouselSection("Madiun Today", _madiunTodayPosts),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistSection() {
    if (playlists.isEmpty) return const SizedBox();

    final PageController controller = PageController(viewportFraction: 0.7);
    int currentPage = 0;

    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (controller.hasClients && playlists.isNotEmpty) {
        currentPage++;
        if (currentPage >= playlists.length) currentPage = 0;
        controller.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Playlist / Live",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Scrollbar(
            thumbVisibility: true,
            child: PageView.builder(
              controller: controller,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPlaylistId = playlist['playlistId'];
                      selectedPlaylistTitle = playlist['title'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            playlist['thumbnail'],
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            playlist['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "${playlist['videoCount']} video",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoCarouselSection(String title,
      List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox();

    final PageController controller = PageController(viewportFraction: 0.7);
    int currentPage = 0;

    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (controller.hasClients && data.isNotEmpty) {
        currentPage++;
        if (currentPage >= data.length) currentPage = 0;
        controller.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: Scrollbar(
            thumbVisibility: true,
            child: PageView.builder(
              controller: controller,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final post = data[index];
                return GestureDetector(
                  onTap: () async {
                    final url = post['url'];
                    if (url != null && await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        post['image'] != null && post['image']!.isNotEmpty
                            ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            post['image'],
                            width: double.infinity,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Container(
                          width: double.infinity,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.white70),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            post['title'] ?? "No Title",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildAllNewsPage() {
    final allPosts = [..._instagramPosts, ..._kabarWarga, ..._madiunTodayPosts];

    if (allPosts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final totalData = allPosts.length;
    final totalPages = (totalData / _perPage).ceil();
    final PageController _pageController =
    PageController(initialPage: _currentPage - 1);

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index + 1;
              });
            },
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * _perPage;
              final endIndex = ((pageIndex + 1) * _perPage).clamp(0, totalData);
              final visiblePosts = allPosts.sublist(startIndex, endIndex);

              final ScrollController _gridController = ScrollController();

              return Scrollbar(
                thumbVisibility: true,
                controller: _gridController,
                child: GridView.builder(
                  controller: _gridController,
                  padding: const EdgeInsets.all(16),
                  itemCount: visiblePosts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final post = visiblePosts[index];
                    return GestureDetector(
                      onTap: () async {
                        final url = post['url'];
                        if (url != null && await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: post['image'] != null &&
                                  post['image']!.isNotEmpty
                                  ? Image.network(
                                post['image'],
                                height: 100,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                height: 100,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                post['title'] ?? "No Title",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        // tobol next prev
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _currentPage > 1
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _currentPage < totalPages
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
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index + 1 ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index + 1
                      ? Colors.white
                      : Colors.white54,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}