import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const TimetablePage(),
    );
  }
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final int hoursInDay = 24;
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
  final PageController pageController = PageController();
  List<List<List<String>>> timetable = List.generate(7, (index) => List.generate(24, (i) => []));
  String currentDay = '월';

  @override
  void initState() {
    super.initState();
    pageController.addListener(_onPageChanged); // 페이지 변경 리스너 추가
  }

  void _onPageChanged() {
    int pageIndex = pageController.page?.round() ?? 0;
    if (pageIndex < days.length) {
      setState(() {
        currentDay = days[pageIndex]; // 현재 요일 업데이트
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 변경된 AppBar
        appBar: AppBar(
          title: Text(currentDay, style: const TextStyle(fontSize: 24)), // 현재 요일 표시
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () => showSummaryModal(context), // 합계 보기 버튼 추가
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (pageController.page! > 0) {
                  pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                if (pageController.page! < days.length - 1) {
                  pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              },
            ),
          ],
        ),

      body: PageView.builder(
        controller: pageController,
        itemCount: days.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, dayIndex) {
          return Container(
            child: ListView.builder(
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
                        width: 200,//얘 걍 가로 값 받아서 정수 넣어야할듯.
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
            ),
          );
        },
      ),
    );
  }
}
