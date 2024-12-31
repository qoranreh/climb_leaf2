import 'package:climb_leaf2/task_goal_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'timetable_page.dart';
import 'calendar_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'package:provider/provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyB1kpRlb_RjtsVgckSkaEv4p9vonylOVOU",
      appId: "1:1061160585967:android:654a96a1dd53b398dae91a",
      messagingSenderId: "1061160585967",
      projectId: "climbleaf-be9d2",
      storageBucket: "climbleaf-be9d2.firebasestorage.app",
    ),
  );
  initializeDateFormatting().then((_) => runApp(
      MultiProvider(providers: [ChangeNotifierProvider(create: (_)=>TaskGoalProvider())],
      child: const MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const SplashScreen(), // 초기 화면을 SplashScreen으로 설정
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 3초 후 TimetablePage로 이동
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TimetablePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white, // 배경색 지정
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 앱 이름 표시
            Text(
              'ClimbLeaf',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            // 로딩 애니메이션
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
