import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DayDetail extends StatefulWidget {
  final DateTime date; 
  const DayDetail({super.key, required this.date});

  @override
  _DayDetailState createState() => _DayDetailState();
}

class _DayDetailState extends State<DayDetail> {
  final Map<String, TextEditingController> _controllers = {
    'breakfast': TextEditingController(),
    'lunch': TextEditingController(),
    'dinner': TextEditingController(),
    'snack': TextEditingController(),
  };
  final Map<String, bool> _isRecurring = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
    'snack': false,
  };
  bool _isLoading = false; 
  Map<String, List<String>> _previousMeals = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snack': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchAndSetLastMeals(); 
  }

  Future<void> _saveMealData() async {
    setState(() => _isLoading = true);
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Fluttertoast.showToast(msg: "Gebruiker niet ingelogd");
      return;
    }

    try {
      for (var entry in _controllers.entries) {
        if (entry.value.text.isNotEmpty) {
          final String formattedDate =
              DateFormat('yyyy-MM-dd').format(widget.date);
          final dateId = await _ensureDateExists(formattedDate, uid);
          final mealId =
              await _ensureMealExists(entry.value.text, entry.key, uid);
          await _linkMealAndDate(mealId, dateId, uid, entry.key);

          if (_isRecurring[entry.key]!) {
            final List<DateTime> remainingWeekdays =
                _findRemainingWeekdays(widget.date, widget.date.weekday - 1);
            for (var day in remainingWeekdays) {
              final String formattedDay = DateFormat('yyyy-MM-dd').format(day);
              final dayDateId = await _ensureDateExists(formattedDay, uid);
              await _linkMealAndDate(mealId, dayDateId, uid, entry.key);
            }
          }
        }
      }

      Fluttertoast.showToast(msg: "Maaltijden succesvol opgeslagen!");
      Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: "Fout bij het opslaan van maaltijden: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<DateTime> _findRemainingWeekdays(DateTime startDate, int weekday) {
    List<DateTime> weekdays = [];
    int daysToAdd = (weekday - (startDate.weekday - 1) + 7) % 7;
    if (daysToAdd == 0) {
      daysToAdd =
          7; 
    }
    DateTime tempDate = startDate.add(Duration(days: daysToAdd));
    while (tempDate.month == startDate.month) {
      weekdays.add(tempDate);
      tempDate = tempDate.add(const Duration(days: 7));
    }
    return weekdays;
  }

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

  Future<void> _linkMealAndDate(
      String mealId, String dateId, String uid, String mealType) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('metadata')
        .doc(dateId)
        .set({mealType: mealId, 'dateId': dateId}, SetOptions(merge: true));
  }

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

  CircleAvatar getMealIcon(String mealType) {
    IconData iconData;
    Color backgroundColor;

    switch (mealType) {
      case 'breakfast':
        iconData = Icons.free_breakfast;
        backgroundColor = Colors.blue[200]!;
        break;
      case 'lunch':
        iconData = Icons.lunch_dining;
        backgroundColor = Colors.green[200]!;
        break;
      case 'dinner':
        iconData = Icons.dinner_dining;
        backgroundColor = Colors.red[200]!;
        break;
      case 'snack':
        iconData = Icons.cookie;
        backgroundColor = Colors.orange[200]!;
        break;
      default:
        iconData = Icons.food_bank; 
        backgroundColor = Colors.grey[200]!;
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: backgroundColor,
      child: Icon(iconData, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).canvasColor,
          elevation: 4.0,
          title: Text(
            DateFormat('EEEE MMMM dd').format(widget.date),
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
            ),
          ),
          centerTitle: true, 

          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: _controllers.entries.map((entry) {
                  return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              getMealIcon(entry.key),
                              const SizedBox(
                                  width: 8), 
                              Expanded(
                                child: TextField(
                                  controller: entry.value,
                                  decoration: InputDecoration(
                                    labelText: entry.key.capitalize(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize
                                      .min, 
                                  children: [
                                    Checkbox(
                                      value: _isRecurring[entry.key],
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _isRecurring[entry.key] = value!;
                                        });
                                      },
                                    ),
                                    const Text('Recurring',
                                        style: TextStyle(
                                            fontSize:
                                                12)), 
                                  ],
                                ),
                              ),
                              Expanded(
                                  child: Align(
                                alignment: Alignment.centerRight,
                                child: DropdownButton<String>(
                                  isExpanded:
                                      false, 
                                  hint: const Text('previous'), 
                                  underline:
                                      Container(),
                                  icon: const Icon(
                                      Icons.arrow_drop_down), 
                                  onChanged: (value) {
                                    setState(() {
                                      _controllers[entry.key]?.text =
                                          value ?? "";
                                    });
                                  },
                                  items: _previousMeals[entry.key]
                                      ?.map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              )),
                            ],
                          )
                        ],
                      ));
                }).toList(),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _saveMealData,
          child: const Icon(Icons.save),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: const BottomAppBar(
          child: SizedBox(height: 56),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
