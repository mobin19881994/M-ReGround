import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:m_reground/core/models/task_model.dart';

class TaskSelectionOverlay extends StatefulWidget {
  const TaskSelectionOverlay({
    super.key,
    required this.level,
    required this.tasks,
    required this.lowLight,
    required this.sensorPermissionDenied,
    required this.cameraPermissionDenied,
    required this.onTaskComplete,
  });

  final TaskLevel level;
  final List<BreakTask> tasks;
  final bool lowLight;
  final bool sensorPermissionDenied;
  final bool cameraPermissionDenied;
  final ValueChanged<BreakTask> onTaskComplete;

  @override
  State<TaskSelectionOverlay> createState() => _TaskSelectionOverlayState();
}

class _TaskSelectionOverlayState extends State<TaskSelectionOverlay> {
  final Map<String, bool> _started = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final bool highlightNonCamera = widget.lowLight || widget.cameraPermissionDenied;

    return Container(
      color: Color.fromRGBO(0, 0, 0, 0.62),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Card(
            margin: const EdgeInsets.all(18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Choose Your Break Task (${_label(widget.level)})',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (highlightNonCamera || widget.sensorPermissionDenied)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Camera or sensor constraints detected. Non-camera options are highlighted for reliability.',
                        ),
                      ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: widget.tasks.map((BreakTask task) {
                        final bool isFallback = highlightNonCamera && task.type != TaskType.camera;
                        final bool started = _started[task.id] == true;
                        return SizedBox(
                          width: 250,
                          child: Card(
                            color: isFallback ? Colors.green.shade50 : null,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(
                                    height: 110,
                                    width: double.infinity,
                                    child: Lottie.asset(
                                      task.visualUrl,
                                      repeat: true,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.animation)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(task.description),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () {
                                            setState(() {
                                              _started[task.id] = true;
                                            });
                                          },
                                          child: Text(started ? 'Started' : 'Start Task'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: started ? () => _complete(task) : null,
                                          child: const Text('Complete Task'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _complete(BreakTask task) {
    setState(() {
      _started.remove(task.id);
    });
    widget.onTaskComplete(task);
  }

  String _label(TaskLevel level) {
    switch (level) {
      case TaskLevel.level1:
        return 'Level 1';
      case TaskLevel.level2:
        return 'Level 2';
      case TaskLevel.level3:
        return 'Level 3';
      case TaskLevel.level4:
        return 'Level 4';
    }
  }
}
