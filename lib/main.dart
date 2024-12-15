import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import 유지
import 'package:intl/date_symbol_data_local.dart';
import 'timetable_page.dart'; // 타임테이블 페이지 import
import 'calendar_page.dart'; // 캘린더 페이지 import

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TimetablePage(), // 분리된 타임테이블 페이지를 home으로 설정
    );
  }
}
