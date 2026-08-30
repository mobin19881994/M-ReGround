enum TaskType { camera, sensor, mindful }

enum TaskLevel { level1, level2, level3, level4 }

class BreakTask {
  const BreakTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.level,
    required this.visualUrl,
  });

  final String id;
  final String title;
  final String description;
  final TaskType type;
  final TaskLevel level;
  final String visualUrl;
}
