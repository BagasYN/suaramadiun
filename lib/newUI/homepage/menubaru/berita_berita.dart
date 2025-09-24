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

    // Auto refresh API key/channel id tiap 40 detik
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

  // === fetch firebase untuk youtube api ===
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
      print('Error fetching data from Firebase: $error');
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
      print('Error fetching data from Firebase: $error');
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
            'https://www.googleapis.com/youtube/v3/playlists?part=snippet,contentDetails&channelId=$youtubeChannelId&maxResults=50&pageToken=${nextPageToken ?? ''}&key=$youtubeApiKey';

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
      print('Error: $e');
      setState(() => isLoadingPlaylist = false);
    }
  }

  // === fetch posts lainnya ===
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
            .map<Map<String, dynamic>>((post) => {
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
            .map((item) => {
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
            .map((item) => {
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

  // === UI ===
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

                // AnimatedSwitcher untuk transisi antar tab
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

  /// === Home ala Spotify (Playlist + Feed) ===
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

    return ListView(
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
    );
  }

  /// === Playlist section (gradient + shadow) ===
  Widget _buildPlaylistSection() {
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
          child: isLoadingPlaylist
              ? const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
              : ListView.builder(
            scrollDirection: Axis.horizontal,
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
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade800.withOpacity(0.8),
                        Colors.black87
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        offset: Offset(2, 4),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
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
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// === Reusable Auto Carousel Section (gradient + shadow) ===
  Widget _buildAutoCarouselSection(String title,
      List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox();

    final PageController controller = PageController(viewportFraction: 0.7);
    int currentPage = 0;

    // Auto slide timer
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (controller.hasClients && data.isNotEmpty) {
        currentPage++;
        if (currentPage >= data.length) {
          currentPage = 0;
        }
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
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade800.withOpacity(0.8),
                        Colors.black87
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        offset: Offset(2, 4),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      post['image'] != null && post['image']!.isNotEmpty
                          ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
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
                            top: Radius.circular(16),
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
        )
      ],
    );
  }

  /// === Paging untuk semua berita (gradient + shadow) ===
  Widget _buildAllNewsPage() {
    final allPosts = [..._instagramPosts, ..._kabarWarga, ..._madiunTodayPosts];

    if (allPosts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final totalData = allPosts.length;
    final totalPages = (totalData / _perPage).ceil();

    final startIndex = (_currentPage - 1) * _perPage;
    final endIndex = (_currentPage * _perPage).clamp(0, totalData);

    final visiblePosts = allPosts.sublist(startIndex, endIndex);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visiblePosts.length,
            itemBuilder: (context, index) {
              final post = visiblePosts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade900.withOpacity(0.8), Colors.black87],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      offset: Offset(2, 4),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: post['image'] != null && post['image']!.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post['image'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.article, color: Colors.white),
                  title: Text(
                    post['title'] ?? "No Title",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final url = post['url'];
                    if (url != null && await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              );
            },
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Prev
                ElevatedButton(
                  onPressed: _currentPage > 1
                      ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    disabledBackgroundColor: Colors.black26,
                  ),
                  child: const Text(
                    "Prev",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                Text(
                  "Halaman $_currentPage dari $totalPages",
                  style: const TextStyle(color: Colors.white),
                ),

                // Tombol Next
                ElevatedButton(
                  onPressed: endIndex < totalData
                      ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    disabledBackgroundColor: Colors.black26,
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
}
