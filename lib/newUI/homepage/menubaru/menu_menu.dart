import 'package:flutter/material.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/wblaporbapak.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/webkontributor.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/webprogram.dart';

class MenuPage extends StatelessWidget {
  final List<Map<String, String>> podcasts = [
    {
      "image": "assets/img/kontributor.png",
      "title": "Kontributor",
      "duration": ""
    },
    {
      "image": "assets/img/program.png",
      "title": "Progam Acara",
      "duration": ""
    },
    {
      "image": "assets/img/laporbapak.png",
      "title": "Lapor Bapak",
      "duration": ""
    },
  ];

  void _handleTap(BuildContext context, String title) {
    if (title == "Kontributor") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebKontributor(),
        ),
      );
    } else if (title == "Progam Acara") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Webprogam(),
        ),
      );
    } else if (title == "Lapor Bapak") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebLaporBapak(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu $title belum tersedia')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double itemSize = MediaQuery.of(context).size.width / 4;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: podcasts.map((podcast) {
          return GestureDetector(
            onTap: () => _handleTap(context, podcast["title"]!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: itemSize,
                  height: itemSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      podcast["image"]!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: itemSize,
                  child: Text(
                    podcast["title"]!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
