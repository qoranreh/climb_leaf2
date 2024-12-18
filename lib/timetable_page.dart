import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'calendar_page.dart';


class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final int hoursInDay = 24;
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
  late final PageController pageController;

  List<List<List<String>>> timetable =
  List.generate(7, (index) => List.generate(24, (i) => [])); // 일주일 데이터 저장

  String currentWeekKey = ""; // 현재 주를 나타내는 키 (yyyy-MM-dd)
  String currentDay = '월';
  DateTime selectedDates = DateTime.now(); // 선택된 날짜
  DateTime focusedDates = DateTime.now(); // 캘린더에서 포커스된 날짜

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0);
    currentWeekKey = _getWeekKey(DateTime.now()); // 주 키 계산
    _loadWeekData(); // 현재 주 데이터 Firestore에서 로드
  }

  @override
  void dispose() {
    pageController.dispose();
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

  // 주의 시작일을 키로 사용 (yyyy-MM-dd 형식)
  String _getWeekKey(DateTime date) {
    DateTime monday = date.subtract(Duration(days: date.weekday - 1));
    return monday.toIso8601String().split('T').first; // yyyy-MM-dd
  }

  //timetable에 저장한 데이터 파이어베이스 저장
  void addTask(int dayIndex, int hourIndex) {
    setState(() {
      timetable[dayIndex][hourIndex].add('New Task');//중첩문서 에러 발생?
    });
    print('Saving week data...');
    _saveWeekData(); // Firestore에 데이터 저장
  }

  void editTask(
      BuildContext context, int dayIndex, int hourIndex, int taskIndex) {
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
                  timetable[dayIndex][hourIndex][taskIndex] =
                      textController.text;
                });
                _saveWeekData(); // Firestore에 데이터 저장
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  timetable[dayIndex][hourIndex].removeAt(taskIndex);
                });
                _saveWeekData(); // Firestore에 데이터 저장
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Firestore에 주차별 데이터 저장--
  //error 에러 여기서 에러발생.. 중첩문때문?--
  Future<void> _saveWeekData() async {
    try {
      Map<String, dynamic> serializedTimetable = {};
      for (int dayIndex = 0; dayIndex < timetable.length; dayIndex++) {
        Map<String, List<String>> dayMap = {};
        for (int hourIndex = 0; hourIndex < timetable[dayIndex].length; hourIndex++) {
          dayMap[hourIndex.toString()] = timetable[dayIndex][hourIndex];
        }
        serializedTimetable[dayIndex.toString()] = dayMap;
      }

      await _firestore.collection('timetables').doc(currentWeekKey).set({
        'days': serializedTimetable,
      });

      print('Data saved for week: $currentWeekKey');
    } catch (e) {
      print('Error saving week data: $e');
    }
  }


  // Firestore에서 주차별 데이터 로드
  Future<void> _loadWeekData() async {
    try {
      final doc = await _firestore.collection('timetables').doc(currentWeekKey).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['days'] != null) {
          setState(() {
            timetable = List.generate(7, (dayIndex) {
              // Firestore의 Map 데이터를 읽어오고, 없는 경우 빈 맵으로 대체
              final dayMap = data['days'][dayIndex.toString()] as Map<String, dynamic>? ?? {};
              return List.generate(24, (hourIndex) {
                // Map에서 시간별 데이터 가져오기. 없으면 빈 리스트 반환
                return List<String>.from(dayMap[hourIndex.toString()] ?? []);
              });
            });
          });
        } else {
          print('No data in days field for week: $currentWeekKey');
        }
      } else {
        print('No document found for week: $currentWeekKey. Initializing empty data.');
      }
    } catch (e) {
      print('Error loading week data: $e');
    }
  }


  PageRouteBuilder _createCalendarPageRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
      const CalendarPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, -1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

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
            onPressed: () {
              Navigator.of(context).push(_createCalendarPageRoute());
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: days.length,
        scrollDirection: Axis.horizontal,
        onPageChanged: (int pageIndex){
          setState(() {
            currentDay=days[pageIndex];
          });
        },
        itemBuilder: (context, dayIndex) {
          return ListView.builder(
            itemCount: hoursInDay,
            itemBuilder: (context, hourIndex) {
              return GestureDetector(
                onDoubleTap: () => addTask(dayIndex, hourIndex),
                child: Row(
                  children: [
                    // 시간 표시
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                      width: 60,
                      child: Text('${hourIndex.toString().padLeft(2, '0')}:00'),
                    ),
                    // 작업 목록 표시
                    Container(
                      width: 200,
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: timetable[dayIndex][hourIndex].length,
                        itemBuilder: (context, taskIndex) {
                          String task = timetable[dayIndex][hourIndex][taskIndex];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: TextButton(
                              onPressed: () => editTask(
                                  context, dayIndex, hourIndex, taskIndex),
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
}
