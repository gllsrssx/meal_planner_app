import 'package:flutter/material.dart';
import 'package:meal_planner_app/overview_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/Account');
            },
          ),
        ],
      ),
      body: OverviewScreen(
        initialStartDate: DateTime.now(),
      ),
    );
  }
}
