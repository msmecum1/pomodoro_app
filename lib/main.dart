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

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  int _workDuration = 25; // minutes
  int _shortBreakDuration = 5; // minutes
  int _longBreakDuration = 15; // minutes

  // Timer controller
  Timer? _timer;
  int _seconds = 25 * 60; // Use _workDuration * 60
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedPomodoros = 0;
  int _totalPomodoros = 4; // 4 pomodoros before long break

  // Task management
  List<String> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  String? _currentTask;

  // Random number generator
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
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

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer!.cancel();

          // Check if we just finished a work session or a break
          if (!_isBreak) {
            // Work session completed
            _completedPomodoros++;

            if (_completedPomodoros < _totalPomodoros) {
              // Start a short break
              _seconds = _shortBreakDuration * 60; // Use short break duration
              _isBreak = true;
              _startTimer();
            } else {
              // Ask for long break or continue
              _showLongBreakDialog();
            }
          } else {
            // Break completed, start next work session
            _seconds = _workDuration * 60; // Use work duration
            _isBreak = false;
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
      _seconds = _workDuration * 60; // Reset to work duration
      _isRunning = false;
      _isBreak = false;
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
              onPressed: () {
                Navigator.pop(context);
              },
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
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
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
              onPressed: () {
                Navigator.pop(context);
              },
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
                  _seconds = _longBreakDuration * 60; // Use long break duration
                  _isBreak = true;
                  _completedPomodoros = 0;
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
                  _seconds = _workDuration * 60; // Back to work duration
                  _isBreak = false;
                  _completedPomodoros = 0;
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

  void _selectRandomTask() {
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add some tasks first')));
      return;
    }

    setState(() {
      _currentTask = _tasks[_random.nextInt(_tasks.length)];
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Your Random Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Focus on this task for your Pomodoro session:'),
              const SizedBox(height: 16),
              Text(
                _currentTask!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _selectRandomTask(); // Pick another random task
              },
              child: const Text('PICK ANOTHER'),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    Color backgroundColor =
        _isBreak ? Colors.red.shade100 : Colors.green.shade100;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        backgroundColor: _isBreak ? Colors.red : Colors.green,
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(
                      Colors.grey.r.toInt(),
                      Colors.grey.g.toInt(),
                      Colors.grey.b.toInt(),
                      0.5,
                    ),
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
                      'Random Task', // New Random Task button
                      Icons.shuffle,
                      _selectRandomTask,
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
