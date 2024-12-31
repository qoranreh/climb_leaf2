import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class TaskGoal {
  final String id;
  final String task;
  final int ratio;
  final int graph;
  final List<String> comments;
  final List<String> images;

  TaskGoal({
    required this.id,
    required this.task,
    required this.ratio,
    required this.graph,
    required this.comments,
    required this.images,
  });
}
