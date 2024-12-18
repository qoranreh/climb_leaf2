import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  final DateTime selectedDay; // 현재 선택된 날짜
  final DateTime focusedDay; // 현재 포커스된 날짜

  const CalendarPage({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime tempSelectedDay; // 사용자가 선택한 날짜
  late DateTime tempFocusedDay; // 캘린더에서 포커스된 날짜

  @override
  void initState() {
    super.initState();
    tempSelectedDay = widget.selectedDay; // 초기 선택 날짜 설정
    tempFocusedDay = widget.focusedDay; // 초기 포커스 날짜 설정
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar Page"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              switch (day.weekday) {
                case 1:
                  return const Center(child: Text('월'));
                case 2:
                  return const Center(child: Text('화'));
                case 3:
                  return const Center(child: Text('수'));
                case 4:
                  return const Center(child: Text('목'));
                case 5:
                  return const Center(child: Text('금'));
                case 6:
                  return const Center(child: Text('토'));
                case 7:
                  return const Center(child: Text('일', style: TextStyle(color: Colors.red)));
              }
              return null;
            },
          ),
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2040, 12, 31),
          locale: 'ko-KR',
          focusedDay: tempFocusedDay, // 현재 포커스된 날짜
          selectedDayPredicate: (day) => isSameDay(tempSelectedDay, day), // 선택된 날짜 강조
          onDaySelected: (selectedDay, focusedDay) {
            // 날짜가 선택될 때 상태를 갱신
            setState(() {
              tempSelectedDay = selectedDay; // 선택된 날짜 갱신
              tempFocusedDay = focusedDay; // 포커스된 날짜 갱신
            });
          },
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
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, tempSelectedDay); // 선택된 날짜 반환
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
