import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({
    super.key,
    required this.selectedDates,
    required this.currentDay,
    required this.taskSummary,
    required this.onTaskAdded,
  });

  final DateTime selectedDates;
  final String currentDay;
  final Map<String, int> taskSummary;
  final VoidCallback onTaskAdded;

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  List<Map<String, dynamic>> taskGoals = [];
  int currentPageIndex = 0;
  String selectedTask = "-";

  @override
  void initState() {
    super.initState();
    selectedTask = "-";
    _loadTaskGoals();
  }

  Future<void> _loadTaskGoals() async {
    final taskGoalRef = FirebaseFirestore.instance.collection('taskGoal');
    final snapshot = await taskGoalRef.get();
    setState(() {
      taskGoals = snapshot.docs.map((doc) {
        final data = doc.data(); // Firestore 문서 데이터
        return {
          ...data, // 기존 데이터 포함
          'id': doc.id, // 문서 ID 추가
        };
      }).toList();
    });
  }

  void _reloadPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GraphPage(
          selectedDates: widget.selectedDates,
          currentDay: widget.currentDay,
          taskSummary: widget.taskSummary,
          onTaskAdded: _reloadPage,
        ),
      ),
    );
  }

  void _showTaskGoalModal() {
    showDialog(
      context: context,
      builder: (context) => TaskGoalModal(
        taskSummary: widget.taskSummary,
        existingTasks: taskGoals.map((goal) => goal['task'] as String).toSet(),
        onTaskSelected: (task) {
          setState(() {
            selectedTask = task;
          });
        },
        onTaskAdded: _reloadPage,
      ),
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

  void _updatePageData(int index) {
    if (taskGoals.isNotEmpty && index < taskGoals.length) {
      final taskGoal = taskGoals[index];
      setState(() {
        selectedTask = taskGoal['task'] ?? "-";
      });
    } else {
      setState(() {
        selectedTask = "-";
      });
    }
  }
  void saveCommentToFirebase(
      String taskId, int index, String expected, String comment) async {
    try {
      final taskGoalRef = FirebaseFirestore.instance.collection('taskGoal').doc(taskId);
      final snapshot = await taskGoalRef.get();

      if (snapshot.exists) {
        List<dynamic> currentComments = snapshot.data()?['comments'] ?? [];

        // 배열 확장 및 특정 위치에 데이터 업데이트
        if (currentComments.length <= index * 2 + 1) {
          currentComments.length = index * 2 + 2; // 길이 조정
        }
        currentComments[index * 2] = expected;
        currentComments[index * 2 + 1] = comment;

        // Firestore에 업데이트
        await taskGoalRef.update({'comments': currentComments});
        _loadTaskGoals(); // Firebase 데이터 다시 로드
      }
    } catch (e) {
      print("Error updating comments: $e");
    }
  }

  void _showCommentModal(BuildContext context, String taskId, int index,
      Function(String expected, String comment) onSave) {
    final expectedController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Comment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: expectedController,
                decoration: const InputDecoration(
                  labelText: "Expected Achievement",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: "Comment",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                onSave(
                  expectedController.text,
                  commentController.text,
                );
                _loadTaskGoals(); // Firebase에서 데이터 다시 가져오기
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
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
              '${widget.selectedDates.year % 100}-${widget.selectedDates.month.toString().padLeft(2, '0')}-${widget.selectedDates.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Text(widget.currentDay, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 30),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Task 및 추가 버튼
            Container(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showTaskGoalModal,
                  ),
                  Text(
                    selectedTask == "-" ||
                        !widget.taskSummary.containsKey(selectedTask)
                        ? selectedTask
                        : "$selectedTask : ${widget.taskSummary[selectedTask]}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
            // 그래프 표시
            Expanded(
              flex: 3,
              child: PageView.builder(
                itemCount: taskGoals.isNotEmpty ? taskGoals.length : 1,
                onPageChanged: (index) {
                  setState(() {
                    currentPageIndex = index;
                  });
                  _updatePageData(index);
                },
                itemBuilder: (context, index) {
                  if (taskGoals.isEmpty) {
                    return const Center(child: Text("No goals added."));
                  }
                  final taskGoal = taskGoals[index];
                  final graphType = taskGoal['graph'] ?? 0;
                  final ratio = taskGoal['ratio'] ?? 100;

                  double dotX = calculateXForDot(
                    widget.taskSummary[selectedTask] ?? 0,
                    ratio,
                  );

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                                  (x) => calculateGraphSpot(graphType, x),
                            ),
                            color: Colors.black,
                            isCurved: false,
                            barWidth: 2,
                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, barData) {
                                return spot.x == dotX;
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
                  );
                },
              ),
            ),
            // ListViewBuilder
            Expanded(
              flex: 4,
              child: ListView.builder(
                itemCount: taskGoals.isNotEmpty ? 4 : 0,
                itemBuilder: (context, index) {
                  if (taskGoals.isEmpty) {
                    return const Center(child: Text("Please add Comment"));
                  }
                  final taskGoal = taskGoals[currentPageIndex];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        GestureDetector(
                          onDoubleTap: () =>
                              _showImageModal(context, taskGoal['id']),
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: GestureDetector(
                            onDoubleTap: () => _showCommentModal(
                              context,
                              taskGoal['id'],
                              index,
                                  (expected, comment) {
                                saveCommentToFirebase(
                                    taskGoal['id'], index, expected, comment);
                              },
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  taskGoal['comments'].length > index * 2 &&
                                      taskGoal['comments'][index * 2] != ""
                                      ? "${taskGoal['comments'][index * 2]}"
                                      : "No Expected Achievement",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  taskGoal['comments'].length > index * 2 + 1 &&
                                      taskGoal['comments'][index * 2 + 1] !=
                                          ""
                                      ? """Comment: 
                                      ${taskGoal['comments'][index * 2 + 1]}"""
                                      : "No Comment",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
void _showImageModal(BuildContext context, String taskId) {
  showDialog(
    context: context,
    builder: (context) {
      String? imageUrl;

      return AlertDialog(
        title: const Text("Add Image"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                // 이미지를 선택하고 Firebase에 업로드
                imageUrl = await _uploadImageToFirebase();
              },
              child: const Text("Choose Image"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (imageUrl != null) {
                // Firestore에 이미지 URL 저장
                await FirebaseFirestore.instance
                    .collection('taskGoal')
                    .doc(taskId)
                    .update({
                  "images": FieldValue.arrayUnion([imageUrl])
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

Future<String?> _uploadImageToFirebase() async {
  // 이미지 선택 및 Firebase Storage 업로드 로직
  // ...
  return "uploaded_image_url"; // 업로드된 이미지 URL 반환
}



class TaskGoalModal extends StatefulWidget {
  const TaskGoalModal({
    super.key,
    required this.taskSummary,
    required this.existingTasks,
    required this.onTaskSelected,
    required this.onTaskAdded,
  });

  final Map<String, int> taskSummary;
  final Set<String> existingTasks;
  final ValueChanged<String> onTaskSelected;
  final VoidCallback onTaskAdded;

  @override
  State<TaskGoalModal> createState() => _TaskGoalModalState();
}

class _TaskGoalModalState extends State<TaskGoalModal> {
  String selectedTask = "";
  int selectedGraph = -1;
  int selectedRatio = -1;
  bool hasDuplicateTask = false;

  void saveToFirestore() async {
    if (widget.existingTasks.contains(selectedTask)) {
      setState(() {
        hasDuplicateTask = true;
      });
    } else if (selectedTask.isNotEmpty &&
        selectedGraph != -1 &&
        selectedRatio != -1) {
      final taskGoalRef = FirebaseFirestore.instance.collection('taskGoal');
      await taskGoalRef.add({
        "task": selectedTask,
        "ratio": selectedRatio,
        "graph": selectedGraph,
        "comments": List.generate(8, (index) => ""),
        "images": List.generate(4, (index) => ""),
      });
      widget.onTaskSelected(selectedTask);
      widget.onTaskAdded();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add New Goal",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Select Task"),
              Container(
                height: 150,
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.taskSummary.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedTask = entry.key;
                            hasDuplicateTask = false;
                          });
                        },
                        child: Text(entry.key),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),
              const Text("Select Graph"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: List.generate(3, (i) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedGraph = i;
                        hasDuplicateTask = false;
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
                        hasDuplicateTask = false;
                      });
                    },
                    child: Text(ratio.toString()),
                  );
                }).toList(),
              ),
              if (hasDuplicateTask)
                const Text(
                  "Task already exists!",
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ElevatedButton(
                onPressed: saveToFirestore,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      hasDuplicateTask ? Colors.red : Colors.blue),
                ),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
