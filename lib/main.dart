import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ToDoScreen(),
    );
  }
}

class ToDoScreen extends StatefulWidget {
  @override
  _ToDoState createState() => _ToDoState();
}

class _ToDoState extends State<ToDoScreen> {
  final List<String> _tasks = []; // Fixed naming
  final List<bool> _completed = []; // Tracks completed tasks
  final TextEditingController _controller = TextEditingController();

  void _addTask() {
    setState(() {
      if (_controller.text.isNotEmpty) {
        _tasks.add(_controller.text);
        _completed.add(false); // New task starts as incomplete
        _controller.clear();
      }
    });
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      _completed.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) { // Fixed parameter
    return Scaffold(
      appBar: AppBar(title: Text('TODO LIST')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter tasks',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(10),
              ),
            ),
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
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: _completed[index], 
                        onChanged: (value) {
                          setState(() {
                            _completed[index] = value!;
                          });
                        },
                      ),
                      title: Text(
                        _tasks[index],
                        style: TextStyle(
                          decoration: _completed[index] ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () => _removeTask(index),
                        icon: Icon(Icons.delete, color: Colors.red),
                      ),
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
