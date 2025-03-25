import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

void main()=>runApp(healthApp());
class healthApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
class HomeScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar:AppBar(title:Text("SehatGo")),
      body:Center(
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: (){}, child: Text("Step counter")),
            ElevatedButton(onPressed: (){}, child: Text("Heart Rate Monitor"))
          ],
        ),
        ),
    );
  }
}
class StepCounter extends StatefulWidget{
  @override
  _StepCounterState createState() => _StepCounterState();
}
class _StepCounterState extends State<StepCounter>{
  int _stepCount=0;
  @override
  void initState() {
    super.initState();
    // Listening to step count updates
    Pedometer.stepCountStream.listen((event) {
      setState(() {
        _stepCount = event.steps;
      });
    });
  }

Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Step Counter")),
      body: Center(
        child: Text(
          'Steps: $_stepCount',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }

}