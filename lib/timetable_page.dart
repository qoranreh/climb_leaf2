import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calendar_page.dart';
import 'package:fl_chart/fl_chart.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final int hoursInDay = 24; // 하루 시간
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일']; // 요일
  late final PageController pageController;

  List<List<List<String>>> timetable =
      List.generate(7, (index) => List.generate(24, (i) => [])); // 일주일 데이터 저장

  String currentWeekKey = ""; // 현재 주를 나타내는 키 (yyyy-MM-dd)
  String currentDay = '월';
  DateTime selectedDates = DateTime.now(); // 선택된 날짜
  DateTime focusedDates = DateTime.now(); // 캘린더에서 포커스된 날짜

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, int> getTaskSummary() {
    Map<String, int> summary = {};
    for (var day in timetable) {
      for (var hourTasks in day) {
        for (var task in hourTasks) {
          if (task != 'New Task') {
            // 'New Task'를 제외
            summary[task] = (summary[task] ?? 0) + 1; // 작업 수 증가
          }
        }
      }
    }
    return summary;
  }

  Map<String, List<DateTime>> taskHistory = {
    "운동": [
      DateTime.now().subtract(Duration(days: 1)),
      DateTime.now().subtract(Duration(days: 3)),
    ],
    "공부": [
      DateTime.now().subtract(Duration(days: 2)),
      DateTime.now().subtract(Duration(days: 3)),
      DateTime.now().subtract(Duration(days: 3)),
    ],
  };
  Map<DateTime, int> taskData = {
    DateTime(2023, 12, 1): 5,
    DateTime(2023, 12, 2): 3,
    DateTime(2023, 12, 3): 8,
  };

  @override
  void initState() {
    super.initState();
    pageController = PageController(
        initialPage: selectedDates.weekday - 1); // 현재 요일에 맞는 페이지로 초기화
    currentWeekKey = _getWeekKey(selectedDates); // 주 키 계산
    _loadWeekData(); // 현재 주 데이터 Firestore에서 로드
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
    Map<String, int> summary = getTaskSummary();
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

  void showSummaryModal(BuildContext context) async {
    // 1. 한 달의 날짜를 생성
    DateTime now = DateTime.now();
    List<DateTime> currentMonthDates = List.generate(
      now.day,
      (index) => DateTime(now.year, now.month, 1).add(Duration(days: index)),
    );

    // 2. Firestore에서 데이터를 가져오기
    List<int> taskCounts = List.filled(31, 0); // 최대 크기 31
    Map<String, int> taskSummary = getTaskSummary(); // 입력된 task 요약
    String selectedTask =
        taskSummary.isNotEmpty ? taskSummary.keys.first : ''; // 초기 선택 Task

    if (selectedTask.isNotEmpty) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('tasks') // Firebase 컬렉션 이름
          .where('date', isGreaterThanOrEqualTo: currentMonthDates.first)
          .where('date', isLessThanOrEqualTo: currentMonthDates.last)
          .get();

      // 날짜별 Task 횟수 집계
      for (var doc in querySnapshot.docs) {
        DateTime date = (doc['date'] as Timestamp).toDate();
        String task = doc['task'];
        if (task == selectedTask) {
          taskCounts[date.day - 1]++;
        }
      }
    }

    // 3. FlSpot 데이터 생성
    List<FlSpot> _generateSpots() {
      return List.generate(
        currentMonthDates.length,
        (index) => FlSpot(index.toDouble(), taskCounts[index].toDouble()),
      );
    }

    // 4. 모달 UI
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Monthly Task Graph',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8.0,
                    children: taskSummary.keys.map((task) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedTask = task;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedTask == task
                              ? Colors.blue
                              : Colors.grey[300],
                        ),
                        child: Text(
                          task,
                          style: TextStyle(
                            color: selectedTask == task
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        minX: 0,
                        maxX: now.day.toDouble() - 1,
                        minY: 0,
                        maxY: taskCounts
                                .reduce((a, b) => a > b ? a : b)
                                .toDouble() +
                            1,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateSpots(),
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [Colors.blue, Colors.lightBlueAccent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  // 빈 데이터 초기화 함수
  void _initializeEmptyTimetable() {
    setState(() {
      timetable =
          List.generate(7, (index) => List.generate(24, (i) => [])); // 빈 리스트 생성
    });
  }

  @override
  Widget build(BuildContext context) {
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
                          child: const Text(
                            '상단 텍스트',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      // 하단 회색 컨테이너
                      Expanded(
                        flex: 3, // 2:8 비율
                        child: Container(
                          color: Colors.white, // 회색 배경
                          alignment: Alignment.bottomRight, // 아래로 정렬

                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.65,
                            height: 150,
                            padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                            color: Colors.black12,
                            child: const Text(
                              '하단 정렬 컨테이너',
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 14),
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
                        onPressed: () {
                          Map<DateTime, Map<String, int>> wrappedTaskData =
                              taskData.map((date, count) {
                            return MapEntry(date, {'defaultTask': count});
                          });
                          showSummaryModal(context);
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
                    itemCount: hoursInDay,
                    itemBuilder: (context, hourIndex) {
                      return GestureDetector(
                        onDoubleTap: () => addTask(dayIndex, hourIndex),
                        // 더블탭으로 작업 추가
                        child: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              width: 60,
                              child: Text(
                                hourIndex.toString().padLeft(2, '0'),
                                style: TextStyle(fontSize: 30),
                              ),
                            ),
                            Container(
                              width: 200,
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    timetable[dayIndex][hourIndex].length,
                                itemBuilder: (context, taskIndex) {
                                  String task =
                                      timetable[dayIndex][hourIndex][taskIndex];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2.0),
                                    child: TextButton(
                                      onPressed: () => editTask(context,
                                          dayIndex, hourIndex, taskIndex),
                                      child: Text(
                                        task,
                                        style: TextStyle(fontSize: 30),
                                      ),
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
            ),
          ),
        ],
      ),
    );
  }
}
