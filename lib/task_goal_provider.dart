import 'package:flutter/material.dart';
import 'provalues.dart';

class TaskGoalProvider with ChangeNotifier {
  TaskGoal? _selectedTaskGoal;

  TaskGoal? get selectedTaskGoal => _selectedTaskGoal;

  void selectTaskGoal(TaskGoal taskGoal) {
    _selectedTaskGoal = taskGoal;
    notifyListeners(); // 상태 변경 알림
  }
}