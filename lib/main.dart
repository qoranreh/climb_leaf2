import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import 유지
import 'package:intl/date_symbol_data_local.dart';
import 'timetable_page.dart'; // 타임테이블 페이지 import
import 'calendar_page.dart'; // 캘린더 페이지 import
import 'package:firebase_core/firebase_core.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 위젯 초기화
  await Firebase.initializeApp(
    options: FirebaseOptions(//엥이게 왜됨 수동 설정인데
      apiKey: "AIzaSyB1kpRlb_RjtsVgckSkaEv4p9vonylOVOU",
      appId: "1:1061160585967:android:654a96a1dd53b398dae91a",
      messagingSenderId: "1061160585967",
      projectId: "climbleaf-be9d2",
      storageBucket: "climbleaf-be9d2.firebasestorage.app",
    ),
  ); // Firebase 초기화
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
