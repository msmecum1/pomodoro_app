import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PomodoroTimer(),
    );
  }
}

// Timer configuration options
enum TimerConfig {
  pomodoro(25, 5, '25/5'),
  short(10, 5, '10/5'),
  extended(50, 10, '50/10');

  final int workDuration; // in minutes
  final int shortBreakDuration; // in minutes
  final String label; // Display label
  const TimerConfig(this.workDuration, this.shortBreakDuration, this.label);
}

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  TimerConfig _currentConfig = TimerConfig.pomodoro;
  int _longBreakDuration = 15;

  Timer? _timer;
  int _seconds = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedPomodoros = 0;
  int _totalPomodoros = 4;

  List<String> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  String? _currentTask;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _seconds = _currentConfig.workDuration * 60;
    _loadTasks();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }

    // If no task is selected and tasks exist, pick a random one
    if (!_isBreak && _currentTask == null && _tasks.isNotEmpty) {
      _currentTask = _tasks[_random.nextInt(_tasks.length)];
    }

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer!.cancel();

          if (!_isBreak) {
            _completedPomodoros++;
            if (_completedPomodoros < _totalPomodoros) {
              _seconds = _currentConfig.shortBreakDuration * 60;
              _isBreak = true;
              _currentTask = null; // Clear task during break
              _startTimer();
            } else {
              _showLongBreakDialog();
            }
          } else {
            _seconds = _currentConfig.workDuration * 60;
            _isBreak = false;
            if (_tasks.isNotEmpty) {
              _currentTask = _tasks[_random.nextInt(_tasks.length)];
            }
            _startTimer();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _resetTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _seconds = _currentConfig.workDuration * 60;
      _isRunning = false;
      _isBreak = false;
      _currentTask = null; // Reset task on full reset
    });
  }

  void _changeConfig(TimerConfig config) {
    setState(() {
      _currentConfig = config;
      _seconds =
          _isBreak ? config.shortBreakDuration * 60 : config.workDuration * 60;
      _isRunning = false;
      _timer?.cancel();
    });
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: _taskController,
            decoration: const InputDecoration(hintText: 'Enter task name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  setState(() {
                    _tasks.add(_taskController.text);
                    _taskController.clear();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveTaskDialog() {
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No tasks to remove')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Task'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_tasks[index]),
                  onTap: () {
                    setState(() {
                      _tasks.removeAt(index);
                      if (_currentTask == _tasks[index]) {
                        _currentTask = null; // Clear if current task is removed
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  void _showTasksDialog() {
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No tasks added yet')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('My Tasks'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_tasks[index]));
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  void _showLongBreakDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Great Job!'),
          content: const Text(
            'You completed 4 pomodoros! Would you like to take a long break or continue with another set?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _seconds = _longBreakDuration * 60;
                  _isBreak = true;
                  _completedPomodoros = 0;
                  _currentTask = null; // Clear task during long break
                });
                _saveTasks();
                Navigator.pop(context);
                _startTimer();
              },
              child: const Text('TAKE LONG BREAK'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _seconds = _currentConfig.workDuration * 60;
                  _isBreak = false;
                  _completedPomodoros = 0;
                  if (_tasks.isNotEmpty) {
                    _currentTask = _tasks[_random.nextInt(_tasks.length)];
                  }
                });
                _saveTasks();
                Navigator.pop(context);
                _startTimer();
              },
              child: const Text('CONTINUE WORKING'),
            ),
          ],
        );
      },
    );
  }

  void _switchRandomTask() {
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add some tasks first')));
      return;
    }

    setState(() {
      // Ensure we pick a different task if possible
      String? newTask;
      do {
        newTask = _tasks[_random.nextInt(_tasks.length)];
      } while (newTask == _currentTask && _tasks.length > 1);
      _currentTask = newTask;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _loadTasks() {
    // Placeholder for loading tasks from persistent storage
  }

  void _saveTasks() {
    // Placeholder for saving tasks to persistent storage
  }

  void _navigateToAboutPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutPage()),
    );
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Timer Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                TimerConfig.values
                    .map(
                      (config) => RadioListTile<TimerConfig>(
                        title: Text(config.label),
                        value: config,
                        groupValue: _currentConfig,
                        onChanged: (value) {
                          if (value != null) {
                            _changeConfig(value);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    )
                    .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor =
        _isBreak ? Colors.red.shade100 : Colors.green.shade100;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        backgroundColor: _isBreak ? Colors.red : Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            tooltip: 'Change Timer Duration',
            onPressed: _showConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Pomodoro',
            onPressed: _navigateToAboutPage,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 40),
            Text(
              _isBreak ? 'Take a Break!' : 'Get Working!',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            if (!_isBreak && _currentTask != null) ...[
              const SizedBox(height: 20),
              Text(
                'Task: $_currentTask',
                style: const TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((0.5 * 255).toInt()),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _formatTime(_seconds),
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.0,
                  children: <Widget>[
                    _buildButton(
                      'Add Task',
                      Icons.add_task,
                      _showAddTaskDialog,
                    ),
                    _buildButton(
                      'Remove Task',
                      Icons.delete,
                      _showRemoveTaskDialog,
                    ),
                    _buildButton('See My Tasks', Icons.list, _showTasksDialog),
                    _buildButton(
                      'Switch Task',
                      Icons.shuffle,
                      _switchRandomTask,
                    ),
                    _isRunning
                        ? _buildButton('Pause Timer', Icons.pause, _pauseTimer)
                        : _buildButton(
                          'Start Timer',
                          Icons.play_arrow,
                          _startTimer,
                        ),
                    _buildButton('Reset Timer', Icons.restart_alt, _resetTimer),
                    _buildInfoCard(
                      'Pomodoro',
                      '$_completedPomodoros/$_totalPomodoros',
                    ),
                    _buildProgressIndicator(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isBreak ? Colors.red.shade300 : Colors.green.shade300,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          value: _completedPomodoros / _totalPomodoros,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            _isBreak ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_completedPomodoros/$_totalPomodoros',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Pomodoro'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'History of the Pomodoro Technique',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'The Pomodoro Technique was developed in the late 1980s by Francesco Cirillo, an Italian university student. Struggling with productivity, Cirillo used a tomato-shaped kitchen timer (hence "Pomodoro," Italian for "tomato") to break his work into focused intervals. He experimented with various time lengths and settled on 25-minute work sessions followed by 5-minute breaks, with a longer break after four cycles. This simple method turned into a widely recognized time management tool.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'How It Helps',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'The Pomodoro Technique boosts productivity and focus by:\n'
                '- **Breaking Work into Manageable Chunks**: 25-minute sessions make large tasks less daunting.\n'
                '- **Encouraging Regular Breaks**: Short breaks prevent burnout and maintain mental clarity.\n'
                '- **Building Momentum**: Completing "pomodoros" provides a sense of accomplishment.\n'
                '- **Reducing Distractions**: Committing to a single task per session enhances concentration.\n'
                '- **Customizable**: Adjust work and break times (like 10/5 or 50/10) to suit your needs.\n\n'
                'This app enhances the classic technique with task management and random task selection to keep your workflow engaging!',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
