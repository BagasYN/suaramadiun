import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SemuaBeritaPage extends StatefulWidget {
  final List<Map<String, dynamic>> instagramPosts;
  final List<Map<String, dynamic>> kabarWargaPosts;
  final List<Map<String, dynamic>> MadiunTodayPosts;

  const SemuaBeritaPage({
    Key? key,
    required this.instagramPosts,
    required this.kabarWargaPosts,
    required this.MadiunTodayPosts,
  }) : super(key: key);

  @override
  _SemuaBeritaPageState createState() => _SemuaBeritaPageState();
}

class _SemuaBeritaPageState extends State<SemuaBeritaPage>
    with TickerProviderStateMixin {
  final int _itemsPerPage = 7;

  int _currentPageInstagram = 1;
  int _currentPageKabarWarga = 1;
  int _currentPageMadiunToday = 1;

  int getTotalPages(int itemCount) {
    return (itemCount / _itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> getPaginatedPosts(
      List<Map<String, dynamic>> posts, int currentPage) {
    final start = (currentPage - 1) * _itemsPerPage;
    final end = (currentPage) * _itemsPerPage;
    return posts.sublist(
      start,
      end > posts.length ? posts.length : end,
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 33, 72, 122),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(186, 141, 86, 15),
                  blurRadius: 4,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color.fromARGB(15, 226, 156, 50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              dividerColor: Colors.white.withOpacity(0.0),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Kabar Warga'),
                Tab(text: 'Instagram'),
                Tab(text: 'MadiunToday'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBeritaList(widget.kabarWargaPosts, 'Kabar Warga',
                    _currentPageKabarWarga, onPageChanged: (page) {
                      setState(() {
                        _currentPageKabarWarga = page;
                      });
                    }),
                _buildBeritaList(
                    widget.instagramPosts, 'Instagram', _currentPageInstagram,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPageInstagram = page;
                      });
                    }),
                _buildBeritaList(widget.MadiunTodayPosts, 'madiuntoday.id',
                    _currentPageMadiunToday, onPageChanged: (page) {
                      setState(() {
                        _currentPageMadiunToday = page;
                      });
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeritaList(
      List<Map<String, dynamic>> allPosts, String label, int currentPage,
      {required Function(int) onPageChanged}) {
    if (allPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inbox, size: 80, color: Colors.white24),
            SizedBox(height: 8),
            Text('Tidak ada berita.', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    final paginatedPosts = getPaginatedPosts(allPosts, currentPage);
    final totalPages = getTotalPages(allPosts.length);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: paginatedPosts.length,
              itemBuilder: (context, index) {
                final post = paginatedPosts[index];
                return Card(
                  elevation: 3,
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final url = post['url'];
                      if (url != null && url.toString().isNotEmpty) {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: post['image'] ?? '',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.public,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    label,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border,
                              color: Colors.grey),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Disimpan ke bookmark')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.grey),
                          onPressed: () {
                            final url = post['url'] ?? '';
                            if (url.isNotEmpty) {
                              Share.share(url);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildPaginationControls(currentPage, totalPages, onPageChanged),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(
      int currentPage, int totalPages, Function(int) onPageChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 6,
        children: List.generate(totalPages, (index) {
          final page = index + 1;
          return GestureDetector(
            onTap: () => onPageChanged(page),
            child: Container(
              padding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: currentPage == page ? Colors.blue : Colors.white54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  color: currentPage == page
                      ? Colors.white
                      : Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
