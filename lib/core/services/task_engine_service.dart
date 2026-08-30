import 'package:m_reground/config/app_config.dart';
import 'package:m_reground/core/models/task_model.dart';

class TaskEngineService {
  TaskEngineService._();

  static final TaskEngineService instance = TaskEngineService._();

  List<BreakTask> tasksForLevel(TaskLevel level) {
    switch (level) {
      case TaskLevel.level1:
        return _level1;
      case TaskLevel.level2:
        return _level2;
      case TaskLevel.level3:
        return _level3;
      case TaskLevel.level4:
        return _level4;
    }
  }

  TaskLevel resolveLevel({
    required int totalUsageMinutesToday,
    required DateTime installDate,
  }) {
    final int installDays = DateTime.now().difference(installDate).inDays;
    if (installDays < AppConfig.gracePeriodDays) {
      return TaskLevel.level1;
    }
    if (totalUsageMinutesToday >= AppConfig.level4TriggerMinutes) {
      return TaskLevel.level4;
    }
    if (totalUsageMinutesToday > AppConfig.level3MaxUsageMinutes) {
      return TaskLevel.level3;
    }
    if (totalUsageMinutesToday > AppConfig.level2MaxUsageMinutes) {
      return TaskLevel.level2;
    }
    return TaskLevel.level1;
  }

  List<BreakTask> choices({
    required TaskLevel level,
    required bool cameraAvailable,
    required bool sensorAvailable,
    required bool lowLight,
  }) {
    final List<BreakTask> pool = tasksForLevel(level);

    final List<BreakTask> camera = pool
        .where((BreakTask task) => task.type == TaskType.camera && cameraAvailable && !lowLight)
        .toList();
    final List<BreakTask> sensor = pool
        .where((BreakTask task) => task.type == TaskType.sensor && sensorAvailable)
        .toList();
    final List<BreakTask> mindful = pool.where((BreakTask task) => task.type == TaskType.mindful).toList();

    return <BreakTask>[
      (camera.isNotEmpty ? camera.first : (sensor.isNotEmpty ? sensor.first : mindful.first)),
      (sensor.isNotEmpty ? sensor.first : (mindful.isNotEmpty ? mindful.first : pool.first)),
      mindful.isNotEmpty ? mindful.first : pool.last,
    ];
  }

  static const List<BreakTask> _level1 = <BreakTask>[
    BreakTask(
      id: 'l1_smile',
      title: '3s Smile',
      description: 'Smile naturally for 3 seconds.',
      type: TaskType.camera,
      level: TaskLevel.level1,
      visualUrl: 'assets/animations/camera_task.json',
    ),
    BreakTask(
      id: 'l1_walk_steps',
      title: '10 Steps Walk',
      description: 'Walk 10 steps with your phone in hand.',
      type: TaskType.sensor,
      level: TaskLevel.level1,
      visualUrl: 'assets/animations/sensor_task.json',
    ),
    BreakTask(
      id: 'l1_breath_hold',
      title: '5s Breath Hold',
      description: 'Pause and hold your breath for 5 seconds.',
      type: TaskType.mindful,
      level: TaskLevel.level1,
      visualUrl: 'assets/animations/mindful_task.json',
    ),
  ];

  static const List<BreakTask> _level2 = <BreakTask>[
    BreakTask(
      id: 'l2_drink_water',
      title: 'Drink Water',
      description: 'Drink 1 glass of water and confirm.',
      type: TaskType.camera,
      level: TaskLevel.level2,
      visualUrl: 'assets/animations/camera_task.json',
    ),
    BreakTask(
      id: 'l2_box_breathing',
      title: '30s Box Breathing',
      description: 'Inhale, hold, exhale, hold for 30 seconds.',
      type: TaskType.sensor,
      level: TaskLevel.level2,
      visualUrl: 'assets/animations/sensor_task.json',
    ),
    BreakTask(
      id: 'l2_pattern',
      title: 'Pattern Focus',
      description: 'Complete a quick pattern match.',
      type: TaskType.mindful,
      level: TaskLevel.level2,
      visualUrl: 'assets/animations/mindful_task.json',
    ),
  ];

  static const List<BreakTask> _level3 = <BreakTask>[
    BreakTask(
      id: 'l3_pose_stretch',
      title: 'Standing Stretch',
      description: 'Do a standing stretch for 20 seconds.',
      type: TaskType.camera,
      level: TaskLevel.level3,
      visualUrl: 'assets/animations/camera_task.json',
    ),
    BreakTask(
      id: 'l3_squats',
      title: '5 Motion Squats',
      description: 'Do 5 squats with controlled motion.',
      type: TaskType.sensor,
      level: TaskLevel.level3,
      visualUrl: 'assets/animations/sensor_task.json',
    ),
    BreakTask(
      id: 'l3_affirmation',
      title: 'Voice Affirmation',
      description: 'Say your affirmation aloud once.',
      type: TaskType.mindful,
      level: TaskLevel.level3,
      visualUrl: 'assets/animations/mindful_task.json',
    ),
  ];

  static const List<BreakTask> _level4 = <BreakTask>[
    BreakTask(
      id: 'l4_cooldown',
      title: '45s Cooldown + Reset',
      description: 'Cooldown for 45 seconds, then complete one Level 3 task.',
      type: TaskType.mindful,
      level: TaskLevel.level4,
      visualUrl: 'assets/animations/mindful_task.json',
    ),
    BreakTask(
      id: 'l4_hard_sensor',
      title: 'Hard Sensor Task',
      description: 'Do a motion reset routine.',
      type: TaskType.sensor,
      level: TaskLevel.level4,
      visualUrl: 'assets/animations/sensor_task.json',
    ),
    BreakTask(
      id: 'l4_hard_camera',
      title: 'Hard Camera Task',
      description: 'Complete an intensive camera challenge.',
      type: TaskType.camera,
      level: TaskLevel.level4,
      visualUrl: 'assets/animations/camera_task.json',
    ),
  ];
}
