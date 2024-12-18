import 'dart:async';
import 'package:flutter/material.dart';
import 'timetable_page.dart'; // TimetablePage를 임포트합니다.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 3초 후에 TimetablePage로 이동
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TimetablePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 로딩 화면 배경색
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            // 앱 이름
            Text(
              'Climbleaf', // 앱 이름을 표시
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            // 로딩 인디케이터
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
