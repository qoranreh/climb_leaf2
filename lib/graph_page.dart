import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphPage extends StatelessWidget {
  const GraphPage({
    super.key,
    required this.selectedDates,
    required this.currentDay,
    required this.taskSummary,
  });

  final DateTime selectedDates;
  final String currentDay;
  final Map<String, int> taskSummary; // Task Summary 데이터를 받아옴

  @override
  Widget build(BuildContext context) {
    void _showTaskGoalModal() {
      showDialog(
        context: context,
        builder: (context) => TaskGoalModal(taskSummary: taskSummary),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100.0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Center(
            child: Text(
              '${selectedDates.year % 100}-${selectedDates.month.toString().padLeft(2, '0')}-${selectedDates.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Text(currentDay, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 30),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(30),
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showTaskGoalModal,
                  ),
                  const Text("코딩 공부"),
                ],
              ),
            ),
            Expanded(
              flex: 7,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.42,
                  padding: const EdgeInsets.all(30),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: false,
                        drawVerticalLine: false,
                        drawHorizontalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            101,
                                (x) {
                              double xValue = x.toDouble();
                              double yValue =
                                  100 / (1 + pow(2, 7 - 0.15 * xValue));
                              return FlSpot(xValue, yValue);
                            },
                          ),
                          color: Colors.black,
                          isCurved: false,
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, barData) {
                              return spot.x == 1;
                            },
                          ),
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
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 7, 0, 0),
                child: ListView.builder(
                  itemCount: taskSummary.length,
                  itemBuilder: (context, index) {
                    final task = taskSummary.entries.elementAt(index);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 16.0),
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 100,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 20),
                          Text(
                            "${task.key} (${task.value})",
                            style: const TextStyle(
                              fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}

class TaskGoalModal extends StatefulWidget {
  const TaskGoalModal({super.key, required this.taskSummary});

  final Map<String, int> taskSummary;

  @override
  State<TaskGoalModal> createState() => _TaskGoalModalState();
}

class _TaskGoalModalState extends State<TaskGoalModal> {
  String selectedTask = "";
  int selectedGraph = -1;
  int selectedRatio = -1;

  void saveToFirestore() async {
    if (selectedTask.isNotEmpty && selectedGraph != -1 && selectedRatio != -1) {
      final taskGoalRef = FirebaseFirestore.instance.collection('taskGoal');
      await taskGoalRef.add({
        "task": selectedTask,
        "ratio": selectedRatio,
        "graph": selectedGraph,
        "comments": List.generate(4, (index) => ""),
        "images": List.generate(4, (index) => ""),
      });
      Navigator.of(context).pop();
    } else {
      print("Please select all options");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Task",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.taskSummary.entries
                .where((entry) => entry.value > 0)
                .map((entry) {
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedTask = entry.key;
                  });
                },
                child: Text(entry.key),
              );
            }).toList(),
            const Divider(),
            const Text("Select Graph"),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedGraph = i;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.bar_chart,
                      color: selectedGraph == i ? Colors.blue : Colors.black,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const Divider(),
            const Text("Select Ratio"),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [100, 200, 400, 1000].map((ratio) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedRatio = ratio;
                    });
                  },
                  child: Text(ratio.toString()),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: saveToFirestore,
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );
  }
}
