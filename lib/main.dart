import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lppl_93fm_suara_madiun/Home2.dart';
import 'package:lppl_93fm_suara_madiun/home.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Suara Madiun',
      home: HomePage2(),
    );
  }
}
