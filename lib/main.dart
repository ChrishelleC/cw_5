import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(AquariumApp());
}

class AquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with TickerProviderStateMixin {
  List<Fish> fishList = [];
  Color selectedColor = Colors.red;
  double speed = 2.0;
  Database? database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings (fishCount INTEGER, speed REAL, color INTEGER)'
        );
      },
      version: 1,
    );
    _loadSettings();
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: speed, vsync: this));
      });
    }
  }

  Future<void> _saveSettings() async {
    await database?.insert(
      'settings',
      {'fishCount': fishList.length, 'speed': speed, 'color': selectedColor.value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _loadSettings() async {
    final List<Map<String, dynamic>> settings = await database!.query('settings');
    if (settings.isNotEmpty) {
      setState(() {
        speed = settings[0]['speed'];
        selectedColor = Color(settings[0]['color']);
        fishList = List.generate(
          settings[0]['fishCount'],
          (_) => Fish(color: selectedColor, speed: speed, vsync: this),
        );
      });
    }
  }

  @override
  void dispose() {
    for (var fish in fishList) {
      fish.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Virtual Aquarium')),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
            child: Stack(children: fishList.map((fish) => fish.widget).toList()),
          ),
          Slider(
            value: speed,
            min: 1,
            max: 5,
            onChanged: (value) => setState(() => speed = value),
          ),
          DropdownButton<Color>(
            value: selectedColor,
            items: [
              DropdownMenuItem(value: Colors.red, child: Text("Red")),
              DropdownMenuItem(value: Colors.green, child: Text("Green")),
              DropdownMenuItem(value: Colors.blue, child: Text("Blue")),
            ],
            onChanged: (color) => setState(() => selectedColor = color!),
          ),
          ElevatedButton(onPressed: _addFish, child: Text("Add Fish")),
          ElevatedButton(onPressed: _saveSettings, child: Text("Save Settings")),
        ],
      ),
    );
  }
}

class Fish {
  final Color color;
  final double speed;
  double x, y;
  late AnimationController controller;
  late Animation<double> animation;

  Fish({required this.color, required this.speed, required TickerProvider vsync})
      : x = Random().nextDouble() * 250,
        y = Random().nextDouble() * 250 {
    controller = AnimationController(
      duration: Duration(milliseconds: (2000 ~/ speed).toInt()),
      vsync: vsync,
    )..repeat(reverse: true);
    animation = Tween<double>(begin: 0, end: 1).animate(controller);
  }

  Widget get widget => AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return Positioned(
        left: (x + animation.value * 50) % 250,
        top: (y + animation.value * 50) % 250,
        child: Container(width: 20, height: 20, color: color),
      );
    },
  );
}
