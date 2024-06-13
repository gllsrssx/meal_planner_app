import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('meals').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var meals = snapshot.data?.docs;
          var popularMeals = getPopularMeals(meals!);
          return ListView.builder(
            itemCount: popularMeals.length,
            itemBuilder: (context, index) {
              var meal = popularMeals[index];
              return ListTile(
                title: Text(meal['name']),
                subtitle: Text('Gekozen: ${meal['count']} keer'),
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> getPopularMeals(List meals) {
    var mealCount = {};
    for (var meal in meals) {
      var ontbijt = meal['ontbijt'];
      var lunch = meal['lunch'];
      var avondeten = meal['avondeten'];
      mealCount[ontbijt] = (mealCount[ontbijt] ?? 0) + 1;
      mealCount[lunch] = (mealCount[lunch] ?? 0) + 1;
      mealCount[avondeten] = (mealCount[avondeten] ?? 0) + 1;
    }

    var popularMeals = mealCount.entries.map((e) {
      return {'name': e.key, 'count': e.value};
    }).toList();

    popularMeals.sort((a, b) => b['count'].compareTo(a['count']));
    return popularMeals;
  }
}
