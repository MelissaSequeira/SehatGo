import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase To-Do App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: ToDoScreen(),
    );
  }
}

class ToDoScreen extends StatefulWidget {
  const ToDoScreen({Key? key}) : super(key: key);

  @override
  State<ToDoScreen> createState() => _ToDoState();
}

class _ToDoState extends State<ToDoScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _taskCollection =
      FirebaseFirestore.instance.collection('tasks');

  Timer? _timer;
  DateTime? _selectedDeadline;

  Set<String> alertedTaskIds = {}; // To avoid duplicate alerts

  @override
  void initState() {
    super.initState();
    _startTaskCheck();
  }

  void _startTaskCheck() {
    _timer = Timer.periodic(Duration(minutes: 2), (timer) {
      _checkTasksForAlerts();
    });
  }

  Future<void> _checkTasksForAlerts() async {
    final querySnapshot =
        await _taskCollection.where('completed', isEqualTo: false).get();

    final now = DateTime.now();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final id = doc.id;

      if (data.containsKey('deadline') && data['deadline'] != null) {
        final deadline = (data['deadline'] as Timestamp).toDate();
        final difference = deadline.difference(now);

        if (difference.inMinutes <= 15 && difference.inMinutes >= 0) {
          if (!alertedTaskIds.contains(id)) {
            _showAlert('⏰ Urgent Task!', 'Task is due within 15 minutes!');
            alertedTaskIds.add(id);
          }
        } else if (difference.inMinutes <= 30 && difference.inMinutes > 15) {
          if (!alertedTaskIds.contains(id)) {
            _showAlert('🔔 Upcoming Task',
                'A task is due in less than 30 minutes!');
            alertedTaskIds.add(id);
          }
        }
      }
    }
  }

  void _showAlert(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Dismiss'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(minutes: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null) return;

    setState(() {
      _selectedDeadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _addTask() async {
    if (_controller.text.isNotEmpty) {
      await _taskCollection.add({
        'text': _controller.text,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'deadline': _selectedDeadline != null
            ? Timestamp.fromDate(_selectedDeadline!)
            : null,
      });
      _controller.clear();
      setState(() {
        _selectedDeadline = null;
      });
    }
  }

  Future<void> _removeTask(String docId) async {
    await _taskCollection.doc(docId).delete();
    alertedTaskIds.remove(docId); // Clear alert tracking on delete
  }

  Future<void> _toggleComplete(String docId, bool current) async {
    await _taskCollection.doc(docId).update({'completed': !current});
    if (!current) {
      alertedTaskIds.remove(docId); // Allow alerts again if marked incomplete
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TODO LIST')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter task',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(10),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickDateTime,
                  icon: Icon(Icons.calendar_today),
                  label: Text('Pick Deadline'),
                ),
                SizedBox(width: 10),
                Text(
                  _selectedDeadline == null
                      ? 'No deadline selected'
                      : '${_selectedDeadline!.toLocal()}'.split('.')[0],
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 147, 106, 179),
                ),
                child: Text('Add Task'),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _taskCollection
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final task = docs[index];
                      final data = task.data() as Map<String, dynamic>;

                      final text = data['text'] ?? '';
                      final completed = data['completed'] ?? false;
                      final deadline = data.containsKey('deadline') &&
                              data['deadline'] != null
                          ? (data['deadline'] as Timestamp).toDate()
                          : null;

                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: completed,
                            onChanged: (_) =>
                                _toggleComplete(task.id, completed),
                          ),
                          title: Text(
                            text,
                            style: TextStyle(
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: deadline != null
                              ? Text(
                                  'Deadline: ${deadline.toLocal()}'
                                      .split('.')[0],
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                )
                              : null,
                          trailing: IconButton(
                            onPressed: () => _removeTask(task.id),
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      );
                    },
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
