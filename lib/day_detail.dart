// Importeer de benodigde pakketten
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Definieer de DayDetail klasse die een StatefulWidget is
class DayDetail extends StatefulWidget {
  final DateTime date; // Datum voor de detailpagina

  // Constructor voor DayDetail met vereiste datumparameter
  const DayDetail({super.key, required this.date});

  @override
  _DayDetailState createState() => _DayDetailState();
}

// De staat van de DayDetail widget
class _DayDetailState extends State<DayDetail> {
  // Map voor het bijhouden van tekstveldcontrollers voor verschillende maaltijden
  final Map<String, TextEditingController> _controllers = {
    'breakfast': TextEditingController(),
    'lunch': TextEditingController(),
    'dinner': TextEditingController(),
    'snack': TextEditingController(),
  };
  bool _isLoading = false; // Laadindicatorstatus
  Map<String, List<String>> _previousMeals = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snack': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchAndSetLastMeals(); // Haal de laatste maaltijden op bij initialisatie
  }

  // Functie om maaltijdgegevens op te slaan
  Future<void> _saveMealData() async {
    setState(() => _isLoading = true);
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Fluttertoast.showToast(msg: "Gebruiker niet ingelogd");
      return;
    }
    final String formattedDate = DateFormat('yyyy-MM-dd').format(widget.date);

    try {
      // Zorg ervoor dat de datum bestaat en verkrijg het ID
      final dateId = await _ensureDateExists(formattedDate, uid);

      // Sla elke maaltijd op als deze niet bestaat
      for (var entry in _controllers.entries) {
        if (entry.value.text.isNotEmpty) {
          final mealId =
              await _ensureMealExists(entry.value.text, entry.key, uid);

          // Koppel de maaltijd aan de datum
          await _linkMealAndDate(mealId, dateId, uid, entry.key);
        }
      }

      Fluttertoast.showToast(msg: "Maaltijden succesvol opgeslagen!");
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Fout bij het opslaan van maaltijden: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Functie om te controleren of een maaltijd bestaat, zo niet, maak deze aan
  Future<String> _ensureMealExists(
      String name, String mealType, String uid) async {
    final mealRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meals')
        .where('name', isEqualTo: name)
        .where('type', isEqualTo: mealType)
        .limit(1);

    final querySnapshot = await mealRef.get();
    if (querySnapshot.docs.isEmpty) {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meals')
          .add({'name': name, 'type': mealType});
      return docRef.id;
    } else {
      return querySnapshot.docs.first.id;
    }
  }

  // Functie om te controleren of een datum bestaat, zo niet, maak deze aan
  Future<String> _ensureDateExists(String date, String uid) async {
    final dateRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dates')
        .where('date', isEqualTo: date)
        .limit(1);

    final querySnapshot = await dateRef.get();
    if (querySnapshot.docs.isEmpty) {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dates')
          .add({'date': date});
      return docRef.id;
    } else {
      return querySnapshot.docs.first.id;
    }
  }

  // Functie om een maaltijd te koppelen aan een datum
  Future<void> _linkMealAndDate(
      String mealId, String dateId, String uid, String mealType) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('metadata')
        .doc(dateId)
        .set({mealType: mealId, 'dateId': dateId}, SetOptions(merge: true));
  }

  // Functie om de laatste maaltijden op te halen en in te stellen
  Future<void> _fetchAndSetLastMeals() async {
    setState(() => _isLoading = true);
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Fluttertoast.showToast(msg: "Gebruiker niet ingelogd");
      return;
    }

    final String formattedDate = DateFormat('yyyy-MM-dd').format(widget.date);
    Map<String, List<String>> tempPreviousMeals = {
      'breakfast': [],
      'lunch': [],
      'dinner': [],
      'snack': [],
    };

    try {
      // Fetch meals for the specific date
      final dateRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dates')
          .where('date', isEqualTo: formattedDate)
          .limit(1);
      final dateSnapshot = await dateRef.get();
      String? dateId;
      if (dateSnapshot.docs.isNotEmpty) {
        dateId = dateSnapshot.docs.first.id;
      }

      if (dateId != null) {
        final metadataRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('metadata')
            .doc(dateId);
        final metadataSnapshot = await metadataRef.get();
        if (metadataSnapshot.exists) {
          Map<String, dynamic> metadata = metadataSnapshot.data()!;
          for (var mealType in _controllers.keys) {
            if (metadata.containsKey(mealType)) {
              final mealId = metadata[mealType];
              final mealDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('meals')
                  .doc(mealId)
                  .get();
              if (mealDoc.exists) {
                _controllers[mealType]?.text = mealDoc.data()?['name'] ?? "";
              }
            }
          }
        }
      }

      // Continue fetching last meals as before
      final mealsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meals');
      final querySnapshot = await mealsRef.get();
      for (var doc in querySnapshot.docs) {
        String mealType = doc.data()['type'];
        String mealName = doc.data()['name'];
        if (tempPreviousMeals.containsKey(mealType)) {
          tempPreviousMeals[mealType]?.add(mealName);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Fout bij het ophalen van vorige maaltijden: $e");
    } finally {
      setState(() {
        _previousMeals = tempPreviousMeals;
        _isLoading = false;
      });
    }
  }

  // Bouw de UI van de widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // make the title dynamic based on the selected date
        title: Text(DateFormat('dd MMMM yy').format(widget.date)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: _controllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: entry.key.capitalize(),
                        ),
                      ),
                      DropdownButton<String>(
                        hint: Text("Selecteer vorige ${entry.key}"),
                        items: _previousMeals[entry.key]?.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _controllers[entry.key]?.text = value ?? "";
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveMealData,
        child: const Icon(Icons.save),
      ),
    );
  }
}

// Extensie om de eerste letter van een string te kapitaliseren
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
