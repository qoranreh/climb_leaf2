import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calendar_page.dart';

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

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: selectedDates.weekday - 1); // 현재 요일에 맞는 페이지로 초기화
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
  void editTask(BuildContext context, int dayIndex, int hourIndex, int taskIndex) {
    // 작업(Task)을 편집하거나 삭제
    TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'), // 다이얼로그 제목
          content: TextField(
            controller: textController, // 입력받을 텍스트 컨트롤러
            decoration: const InputDecoration(hintText: 'Enter task name'), // 힌트 텍스트
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 작업 이름 수정
                setState(() {
                  timetable[dayIndex][hourIndex][taskIndex] =
                      textController.text; // 수정된 작업 이름 저장
                });
                _saveWeekData(); // Firestore에 데이터 저장
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text('OK'), // 확인 버튼
            ),
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

  void _onPageChanged(int pageIndex) {
    setState(() {
      currentDay = days[pageIndex]; // 현재 요일 갱신

      // 선택된 날짜를 페이지 인덱스에 맞게 변경
      int difference = pageIndex - (selectedDates.weekday - 1);
      selectedDates = selectedDates.add(Duration(days: difference)); // 정확한 날짜 갱신
      currentWeekKey = _getWeekKey(selectedDates); // 주 키 갱신
      _loadWeekData(); // Firestore에서 새 데이터 로드
    });
  }

  // 주의 시작일을 키로 사용 (yyyy-MM-dd 형식)
  String _getWeekKey(DateTime date) {
    DateTime monday = date.subtract(Duration(days: date.weekday - 1)); // 해당 주의 월요일 계산
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
              // Firestore의 Map 데이터를 읽어오고, 없는 경우 빈 데이터 생성
              final dayMap = data['days'][dayIndex.toString()] as Map<String, dynamic>? ?? {};
              return List.generate(24, (hourIndex) {
                return List<String>.from(dayMap[hourIndex.toString()] ?? []); // 빈 리스트 기본값
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
        print('No document found for week: $currentWeekKey. Initializing empty data.');
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
      timetable = List.generate(7, (index) => List.generate(24, (i) => [])); // 빈 리스트 생성
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Center(
                child: Text(
                  '${selectedDates.month}/${selectedDates.day}', // 현재 날짜 (MM/DD 형식)
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),)),
        title: Text(currentDay, style: const TextStyle(fontSize: 24)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _navigateToCalendarPage,
          ),
        ],
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: days.length,
        scrollDirection: Axis.horizontal,
        onPageChanged: _onPageChanged, // 페이지 변경 이벤트 처리
        itemBuilder: (context, dayIndex) {
          return ListView.builder(
            itemCount: hoursInDay,
            itemBuilder: (context, hourIndex) {
              return GestureDetector(
                onDoubleTap: () => addTask(dayIndex, hourIndex), // 더블탭으로 작업 추가
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
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
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
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
