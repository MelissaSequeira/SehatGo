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
  @override
  _ToDoState createState() => _ToDoState();
}

class _ToDoState extends State<ToDoScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _taskCollection =
      FirebaseFirestore.instance.collection('tasks');

  Future<void> _addTask() async {
    if (_controller.text.isNotEmpty) {
      await _taskCollection.add({
        'text': _controller.text,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    }
  }

  Future<void> _removeTask(String docId) async {
    await _taskCollection.doc(docId).delete();
  }

  Future<void> _toggleComplete(String docId, bool current) async {
    await _taskCollection.doc(docId).update({'completed': !current});
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
                      final text = task['text'];
                      final completed = task['completed'];
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
