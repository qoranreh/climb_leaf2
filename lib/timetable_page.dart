import 'dart:math';

import 'package:climb_leaf2/task_goal_provider.dart';
import 'package:climb_leaf2/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calendar_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'provalues.dart';
import 'task_goal_provider.dart';

import 'graph_page.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final int hoursInDay = 24; // 하루 시간
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일']; // 요일
  late final PageController pageController;

  final ScrollController hourScrollController =
      ScrollController(); // 시간별 스크롤 컨트롤러
  int currentHour = DateTime.now().hour; // 현재 시간

  List<List<List<String>>> timetable =
      List.generate(7, (index) => List.generate(24, (i) => [])); // 일주일 데이터 저장

  List<FlSpot> generateGraphSpots(TaskGoal taskGoal) {
    final graphType = taskGoal.graph; // TaskGoal 객체에서 graph 가져오기
    return List.generate(
      101, // X값 범위 (0~100)
          (x) => calculateGraphSpot(graphType, x), // 각 X값에 대해 Spot 생성
    );
  }

  String currentWeekKey = ""; // 현재 주를 나타내는 키 (yyyy-MM-dd)
  String currentDay = '월';
  DateTime selectedDates = DateTime.now(); // 선택된 날짜
  DateTime focusedDates = DateTime.now(); // 캘린더에서 포커스된 날짜

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getTaskSummary() async {
    Map<String, int> summary = {};

    try {
      // Firestore에서 모든 timetables 문서 가져오기
      final querySnapshot = await _firestore.collection('timetables').get();

      // 각 문서 데이터를 읽어와 taskSummary 계산
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('days')) {
          final days = data['days'] as Map<String, dynamic>;

          for (var day in days.values) {
            final dayMap = day as Map<String, dynamic>;

            for (var hourTasks in dayMap.values) {
              final tasks = List<String>.from(hourTasks ?? []);
              for (var task in tasks) {
                if (task != 'New Task') {
                  summary[task] = (summary[task] ?? 0) + 1; // 작업 수 증가
                }
              }
            }
          }
        }
      }

      print("Task Summary: $summary");
    } catch (e) {
      print("Error fetching task summary: $e");
    }

    return summary;
  }

  Future<void> loadTaskSummary() async {
    final summary = await getTaskSummary();
    setState(() {
      taskSummary = summary; // taskSummary 업데이트
    });
  }

  Map<String, int> taskSummary = {};
  Map<DateTime, int> taskData = {
    DateTime(2023, 12, 1): 5,
    DateTime(2023, 12, 2): 3,
    DateTime(2023, 12, 3): 8,
  };

  @override
  @override
  void initState() {
    super.initState();
    pageController = PageController(
        initialPage: selectedDates.weekday - 1); // 현재 요일에 맞는 페이지로 초기화
    currentWeekKey = _getWeekKey(selectedDates); // 주 키 계산
    _loadWeekData(); // 현재 주 데이터 Firestore에서 로드

    WidgetsBinding.instance.addPostFrameCallback((_) {
      hourScrollController.jumpTo(currentHour * 50.0); // 시간당 100픽셀 간격 (화면조정)
    });

    hourScrollController.addListener(() {
      print("Current Scroll Offset: ${hourScrollController.offset}");
    });

    // Task Summary 로드
    loadTaskSummary();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // 작업 추가 메서드
  void addTask(int dayIndex, int hourIndex) {
    // 특정 요일(dayIndex)와 시간(hourIndex)에 작업 추가
    setState(() {
      timetable[dayIndex][hourIndex].add('New Task'); // 기본 작업 이름
    });
    print('Saving week data...'); // 디버깅용 출력
    _saveWeekData(); // Firestore에 데이터 저장
  }

  // 작업 편집 및 삭제 메서드
  void editTask(BuildContext context, int dayIndex, int hourIndex,
      [int? taskIndex]) {
    TextEditingController textController = TextEditingController();

    // 요약 데이터를 가져와서 상위 3개의 작업만 표시
    final summary = taskSummary;
    List<MapEntry<String, int>> sortedEntries = summary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // value 높은 순 정렬

    List<String> topTasks = sortedEntries
        .take(3) // 상위 3개 선택
        .map((e) => e.key) // MapEntry에서 key만 추출
        .toList();

    // 기존 작업명을 텍스트 입력창에 표시 (수정 모드일 경우)
    if (taskIndex != null) {
      textController.text = timetable[dayIndex][hourIndex][taskIndex];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'), // 다이얼로그 제목
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController, // 입력받을 텍스트 컨트롤러
                decoration: const InputDecoration(
                    hintText: 'Enter task name'), // 힌트 텍스트
              ),
              const SizedBox(height: 8.0), // 간격 추가
              if (topTasks.isNotEmpty) ...[
                const Text(
                  'Suggestions:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: topTasks.map((task) {
                    return ElevatedButton(
                      onPressed: () {
                        textController.text = task; // 버튼 클릭 시 텍스트 입력창에 자동 입력
                      },
                      child: Text(task),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 작업 수정 또는 추가
                setState(() {
                  if (taskIndex != null) {
                    // 기존 작업 수정
                    timetable[dayIndex][hourIndex][taskIndex] =
                        textController.text;
                  } else {
                    // 새 작업 추가
                    timetable[dayIndex][hourIndex].add(textController.text);
                  }
                });
                _saveWeekData(); // Firestore에 데이터 저장
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text('OK'), // 확인 버튼
            ),
            if (taskIndex != null)
              TextButton(
                onPressed: () {
                  // 작업 삭제
                  setState(() {
                    timetable[dayIndex][hourIndex].removeAt(taskIndex); // 작업 제거
                  });
                  _saveWeekData(); // Firestore에 데이터 저장
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                },
                child: const Text('Delete'), // 삭제 버튼
              ),
          ],
        );
      },
    );
  }

  FlSpot calculateGraphSpot(int graphType, int x) {
    double xValue = x.toDouble();
    double yValue;

    if (graphType == 0) {
      yValue = 100 / (1 + pow(2, 5 - 0.1 * xValue));
    } else if (graphType == 1) {
      yValue = xValue;
    } else if (graphType == 2) {
      yValue = 0.01 * pow(xValue, 2);
    } else {
      yValue = 0.0;
    }

    return FlSpot(xValue, yValue);
  }

  double calculateXForDot(int taskValue, int ratio) {
    if (ratio == 0) return 0;
    return taskValue / (ratio / 100);
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      currentDay = days[pageIndex]; // 현재 요일 갱신

      // 선택된 날짜를 페이지 인덱스에 맞게 변경
      int difference = pageIndex - (selectedDates.weekday - 1);
      selectedDates =
          selectedDates.add(Duration(days: difference)); // 정확한 날짜 갱신
      currentWeekKey = _getWeekKey(selectedDates); // 주 키 갱신
      _loadWeekData(); // Firestore에서 새 데이터 로드
    });
  }

  // 주의 시작일을 키로 사용 (yyyy-MM-dd 형식)
  String _getWeekKey(DateTime date) {
    DateTime monday =
        date.subtract(Duration(days: date.weekday - 1)); // 해당 주의 월요일 계산
    return monday.toIso8601String().split('T').first; // yyyy-MM-dd 포맷 반환
  }

  Future<void> _navigateToCalendarPage() async {
    final selectedDayFromCalendar = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (context) => CalendarPage(
          selectedDay: selectedDates,
          focusedDay: focusedDates,
        ),
      ),
    );

    if (selectedDayFromCalendar != null) {
      setState(() {
        selectedDates = selectedDayFromCalendar;
        focusedDates = selectedDayFromCalendar;
        currentDay = days[selectedDates.weekday - 1];
        currentWeekKey = _getWeekKey(selectedDates); // 주차 계산
        pageController.jumpToPage(selectedDates.weekday - 1); // 선택된 요일로 이동
        _loadWeekData(); // Firestore 데이터 로드
      });
    }
  }

  // Firestore에 주차별 데이터 저장
  Future<void> _saveWeekData() async {
    try {
      Map<String, dynamic> serializedTimetable = {};
      for (int dayIndex = 0; dayIndex < timetable.length; dayIndex++) {
        Map<String, List<String>> dayMap = {};
        for (int hourIndex = 0;
            hourIndex < timetable[dayIndex].length;
            hourIndex++) {
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
      final doc =
          await _firestore.collection('timetables').doc(currentWeekKey).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['days'] != null) {
          setState(() {
            timetable = List.generate(7, (dayIndex) {
              // Firestore의 Map 데이터를 읽어오고, 없는 경우 빈 데이터 생성
              final dayMap =
                  data['days'][dayIndex.toString()] as Map<String, dynamic>? ??
                      {};
              return List.generate(24, (hourIndex) {
                return List<String>.from(
                    dayMap[hourIndex.toString()] ?? []); // 빈 리스트 기본값
              });
            });
          });
        } else {
          // 문서는 있지만 데이터가 없는 경우
          print('No data in days field for week: $currentWeekKey');
          _initializeEmptyTimetable(); // 빈 데이터로 초기화
        }
      } else {
        // 문서가 없는 경우
        print(
            'No document found for week: $currentWeekKey. Initializing empty data.');
        _initializeEmptyTimetable(); // 빈 데이터로 초기화
      }
    } catch (e) {
      print('Error loading week data: $e');
      _initializeEmptyTimetable(); // 에러 발생 시 기본값 설정
    }
  }

  void _reloadPage() {
    setState(() {
      // 필요한 데이터를 다시 로드하거나 UI 업데이트 수행
      print("Reload triggered from GraphPage!");
    });
  }

  // 빈 데이터 초기화 함수
  void _initializeEmptyTimetable() {
    setState(() {
      timetable =
          List.generate(7, (index) => List.generate(24, (i) => [])); // 빈 리스트 생성
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskGoal = Provider.of<TaskGoalProvider>(context).selectedTaskGoal;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100.0,
        leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Center(
              child: Text(
                '${selectedDates.year % 100}-${selectedDates.month.toString().padLeft(2, '0')}-${selectedDates.day.toString().padLeft(2, '0')}', // YY-MM-DD 형식
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),
        centerTitle: true,
        actions: [
          Text(currentDay, style: const TextStyle(fontSize: 20)),
          SizedBox(
            width: 30,
          )
        ],
      ),
      body: Column(
        children: [
          // 위쪽 영역
          Expanded(
            flex: 1, // 전체 상단 공간 비율
            child: Row(
              children: [
                // 좌측 공간
                Expanded(
                  flex: 4, // 9:1 비율
                  child: Column(
                    children: [
                      // 상단 텍스트
                      Expanded(
                        flex: 2, // 2:8 비율
                        child: Container(
                          color: Colors.white,
                          alignment: Alignment.bottomLeft,
                          margin: EdgeInsets.fromLTRB(60, 0, 0, 0),
                          child: Consumer<TaskGoalProvider>(
                            builder: (context, taskGoalProvider, child) {
                              final selectedTask =
                                  taskGoalProvider.selectedTaskGoal?.task ??
                                      "No Task Selected";
                              return Text(
                                selectedTask, // Provider에서 가져온 선택된 task 표시
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // 하단 회색 컨테이너
              Expanded(
                flex: 3, // 하단 회색 컨테이너
                child: Container(
                  color: Colors.white, // 배경색
                  alignment: Alignment.bottomRight, // 아래쪽 정렬
                  child: CustomPaint(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black12, // 회색 배경
                      ),
                      width: MediaQuery.of(context).size.width * 0.65,
                      height: 150,
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Consumer<TaskGoalProvider>(
                        builder: (context, taskGoalProvider, child) {
                          final taskGoal = taskGoalProvider.selectedTaskGoal;
                          if (taskGoal == null) {
                            return const Center(
                              child: Text("No Task Goal Selected"),
                            );
                          }

                          final spots = generateGraphSpots(taskGoal);

                          return LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: false, // 격자 표시 비활성화
                              ),
                              borderData: FlBorderData(show: false), // 테두리 표시 비활성화
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // 상단 수치 비활성화
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // 우측 수치 비활성화
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Y축 수치 비활성화
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)), // X축 수치 활성화
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    101, // X값의 범위 (0 ~ 100)
                                        (x) => calculateGraphSpot(taskGoal.graph, x), // graphType에 따른 Spot 생성
                                  ),
                                  color: Colors.black,
                                  isCurved: false, // 직선 그래프
                                  barWidth: 2,
                                  dotData: FlDotData(
                                    show: true,
                                    checkToShowDot: (spot, barData) {
                                      final dotX = calculateXForDot(
                                        taskSummary[taskGoal.task] ?? 0, // taskSummary에서 값 가져오기
                                        taskGoal.ratio, // 작업 비율
                                      );
                                      return spot.x == dotX;
                                    },), // 점 표시
                                ),
                              ],
                              minX: 0,
                              maxX: 100,
                              minY: 0,
                              maxY: 100,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

                    ],
                  ),
                ),
                // 우측 공간
                Expanded(
                  flex: 1, // 9:1 비율
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // 위에서부터 정렬
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart),
                        onPressed: () async {
                          final summary =
                              await getTaskSummary(); // 전체 요약 데이터 가져오기
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => GraphPage(
                                selectedDates: selectedDates,
                                currentDay: currentDay,
                                taskSummary: summary, // 전체 taskSummary 전달
                                onTaskAdded: _reloadPage,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: _navigateToCalendarPage,
                      ),
                      SizedBox(height: 10),
                      Icon(Icons.account_circle, color: Colors.black),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 아래쪽 ListView.builder
          Expanded(
            flex: 2, // 비율 조정 가능
            child: Container(
              padding: EdgeInsets.fromLTRB(30, 50, 30, 60),
              color: Colors.white,
              child: PageView.builder(
                controller: pageController,
                itemCount: days.length,
                scrollDirection: Axis.horizontal,
                onPageChanged: _onPageChanged,
                // 페이지 변경 이벤트 처리
                itemBuilder: (context, dayIndex) {
                  return ListView.builder(
                    controller: dayIndex == selectedDates.weekday - 1
                        ? hourScrollController
                        : null,
                    itemCount: hoursInDay,
                    itemBuilder: (context, hourIndex) {
                      bool isCurrentHour = hourIndex == currentHour;
                      return GestureDetector(
                        onDoubleTap: () => addTask(dayIndex, hourIndex),
                        // 더블탭으로 작업 추가
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                color: isCurrentHour
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.transparent,
                                alignment: Alignment.center,
                                child: Text(
                                  hourIndex.toString().padLeft(2, '0'),
                                  style: TextStyle(fontSize: 25),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Container(
                                height: 50,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      timetable[dayIndex][hourIndex].length,
                                  itemBuilder: (context, taskIndex) {
                                    String task = timetable[dayIndex][hourIndex]
                                        [taskIndex];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2.0),
                                      child: TextButton(
                                        onPressed: () => editTask(context,
                                            dayIndex, hourIndex, taskIndex),
                                        child: Text(
                                          task,
                                          style: TextStyle(fontSize: 25),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
