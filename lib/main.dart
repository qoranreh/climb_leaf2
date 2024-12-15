import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(MyApp()));
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
  List<List<List<String>>> timetable =
      List.generate(7, (index) => List.generate(24, (i) => []));
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

  PageRouteBuilder _createCalendarPageRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CalendarPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, -1.0); // 위에서 아래로
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
              }),
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
                          String task =
                              timetable[dayIndex][hourIndex][taskIndex];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
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
}

class CalendarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar Page"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          calendarBuilders: CalendarBuilders(dowBuilder: (context, day) {
            switch (day.weekday) {
              case 1:
                return const Center(
                  child: Text('월'),
                );
              case 2:
                return const Center(
                  child: Text('화'),
                );
              case 3:
                return const Center(
                  child: Text('수'),
                );
              case 4:
                return const Center(
                  child: Text('목'),
                );
              case 5:
                return const Center(
                  child: Text('금'),
                );
              case 6:
                return const Center(
                  child: Text('토'),
                );
              case 7:
                return const Center(
                  child: Text(
                    '일',
                    style: TextStyle(color: Colors.red),
                  ),
                );
            }
          }),
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          locale: 'ko-KR',
          focusedDay: DateTime.now(),
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false, // 포맷 버튼 숨김
            titleCentered: true,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            print("Selected day: $selectedDay");
          },
        ),
      ),
    );
  }
}
