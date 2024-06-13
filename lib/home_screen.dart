import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wat eten we vandaag?'),
      ),
      body: const WeekView(),
    );
  }
}

class WeekView extends StatelessWidget {
  const WeekView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('meals').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var meals = snapshot.data?.docs;
        return ListView.builder(
          itemCount: meals?.length,
          itemBuilder: (context, index) {
            var meal = meals?[index];
            return ExpansionTile(
              title: Text(meal?['date']),
              children: <Widget>[
                Text('Ontbijt: ${meal?['ontbijt']}'),
                Text('Lunch: ${meal?['lunch']}'),
                Text('Avondeten: ${meal?['avondeten']}'),
              ],
            );
          },
        );
      },
    );
  }
}
