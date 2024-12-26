import 'dart:math'; // pow 함수 사용을 위한 import
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphPage extends StatelessWidget {
  const GraphPage({super.key, this.selectedDates, this.currentDay});

  final selectedDates;
  final currentDay;

  @override
  Widget build(BuildContext context) {
    //예제데이터
    final List<Map<String, dynamic>> items = [
      {"image": Icons.code, "title": "코딩 공부"},
      {"image": Icons.fitness_center, "title": "운동하기"},
      {"image": Icons.local_dining, "title": "다이어트"},
      {"image": Icons.book, "title": "독서하기"},
    ];

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
      body: Container(//마진용
        
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(//Task와 addIcon
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Icon(Icons.add),Text("코딩공부")],
              )
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(//그래프 그리는 상자
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(16)),
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.42,//그래프 상자 높이
                // 그래프 크기
                padding: const EdgeInsets.all(30),
                child: LineChart(
                  LineChartData(
                    // 격자 표시 비활성화
                    gridData: FlGridData(
                      show: false, // 격자 표시 여부
                      drawVerticalLine: false, // 수직선 표시 비활성화
                      drawHorizontalLine: false, // 수평선 표시 비활성화
                    ),
                    borderData: FlBorderData(show: false),
                    // 테두리 숨김
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // 상단 수치 비활성화
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // 우측 수치 비활성화
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // Y축 수치 비활성화
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true), // X축 수치 활성화
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          101,
                          (x) {
                            double xValue = x.toDouble(); // x 값을 실수형으로 변환
                            double yValue =
                                100 / (1 + pow(2, 7 - 0.15 * xValue)); // y 계산
                            return FlSpot(xValue, yValue); // x와 y 값으로 FlSpot 생성
                          },
                        ),
                        isCurved: false, // 직선 그래프
                        barWidth: 2, // 선 두께
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) {
                            return spot.x == 1; // x = 1에서만 점 표시
                          },
                        ), // 점 숨김
                      ),
                    ],
                    minX: 0,
                    maxX: 100,
                    minY: 0,
                    maxY: 100,
                  ),
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.2,
              child: Expanded(
                child: ListView.builder(
                  itemCount: items.length, // 항목 수
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 16.0),
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          Container(
                            child: Icon(
                              items[index]["image"], // 아이콘
                              size: 100,
                              color: Colors.blueAccent,
                            ),
                            decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          const SizedBox(width: 20), //가로 사이 공간
                          Text(
                            items[index]["title"], // 제목?
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
              child: const Text(
                "Recent activities : 코딩공부 | 운동하기 | 다이어트",
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
