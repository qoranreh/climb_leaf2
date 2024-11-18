import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
      home: const TimetablePage(),
    );
  }
}

//타임테이블 위젯 스테이트 전달?
class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}
//타임테이블 페이지 스테이트 관리 - 엥 여기가 다 감싸고 있는데?
class _TimetablePageState extends State<TimetablePage> {
  //state저장
  final int hoursInDay = 24;
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
  late final PageController pageController;
  List<List<List<String>>> timetable = List.generate(7, (index) => List.generate(24, (i) => []));
  String currentDay = '월';


  @override
  //initstate? 있었는데 didChangeDepen~ 으로 변경함.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pageController = PageController(initialPage: 0);
    pageController.addListener(_onPageChanged);
    if (pageController.hasClients) {
      currentDay = days[pageController.page?.round() ?? 0];
    }
  }

  @override
  void dispose() {
    pageController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  void _onPageChanged() {
    int? pageIndex = pageController.page?.round();
    if (pageIndex != null && pageIndex < days.length) {
      setState(() {
        currentDay = days[pageIndex];
      });
    }
  }

  void addTask(int dayIndex, int hourIndex) {
    setState(() {
      timetable[dayIndex][hourIndex].add('New Task');
    });
  }

  void editTask(BuildContext context, int dayIndex, int hourIndex, int taskIndex) {
    TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: 'Enter task name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  timetable[dayIndex][hourIndex][taskIndex] = textController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  timetable[dayIndex][hourIndex].removeAt(taskIndex);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Map<String, int> getTaskSummary() {
    Map<String, int> summary = {};
    for (var day in timetable) {
      for (var hourTasks in day) {
        for (var task in hourTasks) {
          summary[task] = (summary[task] ?? 0) + 1;
        }
      }
    }
    return summary;
  }


  void showSummaryModal(BuildContext context) {
    Map<String, int> summary = getTaskSummary();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: summary.entries.map((entry) {
              return ListTile(
                title: Text('${entry.key}: ${entry.value}'),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCustomModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54, // 배경 색상
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 700, // 전체 모달창 크기
            width: MediaQuery.of(context).size.width , // 좌측 여백 설정
            margin: const EdgeInsets.only(top: 0),
            padding: const EdgeInsets.only(top:50), // 내부 여백 설정
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(43),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 제목 및 텍스트 영역
                Column(
                  children: [
                    Text(
                      "Custom Modal",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 20), // 제목과 문장 사이의 간격
                    Text(
                      "This modal slides from the top!",
                      style: TextStyle(fontSize: 16), // 적절한 폰트 크기 설정
                      textAlign: TextAlign.center, // 중앙 정렬
                    ),
                  ],
                ),
                // 버튼 영역
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Close"),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation =
        Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(animation);
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentDay, style: const TextStyle(fontSize: 24)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => showSummaryModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
              onPressed: () => _showCustomModal(context)),

        ],
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: days.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, dayIndex) {
          return ListView.builder(
            itemCount: hoursInDay,
            itemBuilder: (context, hourIndex) {
              return GestureDetector(
                onDoubleTap: () => addTask(dayIndex, hourIndex),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text('${hourIndex.toString().padLeft(2, '0')}:00'),
                    ),
                    Container(
                      width: 200,
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: timetable[dayIndex][hourIndex].length,
                        itemBuilder: (context, taskIndex) {
                          String task = timetable[dayIndex][hourIndex][taskIndex];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: TextButton(
                              onPressed: () => editTask(context, dayIndex, hourIndex, taskIndex),
                              child: Text(task),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

    );
  }
}
