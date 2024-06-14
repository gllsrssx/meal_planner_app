import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'day_detail.dart';

class OverviewScreen extends StatefulWidget {
  final DateTime initialStartDate;

  const OverviewScreen({super.key, required this.initialStartDate});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late PageController _pageController;
  late DateTime _currentStartDate;

  @override
  void initState() {
    super.initState();
    _currentStartDate = widget.initialStartDate;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 4.0,
        title: Text(
            '${DateFormat('MMMM dd').format(_currentStartDate)} - ${DateFormat('dd').format(_currentStartDate.add(const Duration(days: 6)))}'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: () {
            _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              final today = DateTime.now();
              final startOfWeek = today; 
              final difference =
                  startOfWeek.difference(widget.initialStartDate).inDays;
              final pageToJump = difference ~/ 7;
              _pageController.jumpToPage(pageToJump);
              setState(() {
                _currentStartDate = startOfWeek;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right),
            onPressed: () {
              _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentStartDate =
                widget.initialStartDate.add(Duration(days: 7 * index));
          });
        },
        itemBuilder: (context, pageIndex) {
          final weekStartDate =
              widget.initialStartDate.add(Duration(days: 7 * pageIndex));
          return ListView.builder(
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = weekStartDate.add(Duration(days: index));
              final dayName = DateFormat('EEEE d').format(day);
              return Padding(
                padding:
                    const EdgeInsets.all(3.0), 
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10.0), 
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 3.0,
                        horizontal: 6.0), 
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                          ),
                        ),
                        FutureBuilder<Map<String, bool>>(
                          future: getMealsForDay(day),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const SizedBox
                                  .shrink(); 
                            }
                            final meals = snapshot.data!;
                            List<Widget> children = [];

                            if (meals['breakfast'] == true) {
                              children.add(CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue[200],
                                child:
                                    const Icon(Icons.free_breakfast, size: 16),
                              ));
                            }
                            if (meals['lunch'] == true) {
                              if (children.isNotEmpty) {
                                children
                                    .add(const SizedBox(width: 8)); 
                              }
                              children.add(CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.green[200],
                                child: const Icon(Icons.lunch_dining, size: 16),
                              ));
                            }
                            if (meals['dinner'] == true) {
                              if (children.isNotEmpty) {
                                children
                                    .add(const SizedBox(width: 8)); 
                              }
                              children.add(CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red[200],
                                child:
                                    const Icon(Icons.dinner_dining, size: 16),
                              ));
                            }
                            if (meals['snack'] == true) {
                              if (children.isNotEmpty) {
                                children
                                    .add(const SizedBox(width: 8)); 
                              }
                              children.add(CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.orange[200],
                                child: const Icon(Icons.cookie, size: 16),
                              ));
                            }

                            return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: children);
                          },
                        ),
                      ],
                    ),
                    onTap: () => _showMealsPopup(context, day),
                    onLongPress: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DayDetail(date: day),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                        });
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, String>>> getDetailedMealsForDay(
      DateTime date) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("User not logged in");
    }

    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    print("Fetching meals for date: $formattedDate"); 

    List<Map<String, String>> detailedMeals = [];

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
      } else {
        print(
            "No meals found for the specified date: $formattedDate"); 
        return [];
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
          for (var mealType in metadata.keys) {
            final mealId = metadata[mealType];
            final mealDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('meals')
                .doc(mealId)
                .get();
            if (mealDoc.exists) {
              detailedMeals.add(
                  {'meal': mealType, 'details': mealDoc.data()?['name'] ?? ""});
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching meals for day: $e");
    }

    return detailedMeals;
  }

  void _showMealsPopup(BuildContext context, DateTime day) async {
    List<Map<String, String>> meals = await getDetailedMealsForDay(day);
    final Map<String, IconData> mealIcons = {
      'breakfast': Icons.free_breakfast,
      'lunch': Icons.lunch_dining,
      'dinner': Icons.dinner_dining,
      'snack': Icons.cookie,
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: meals.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: meals.map((meal) {
                    IconData icon = mealIcons[meal['meal']] ?? Icons.error;
                    return ListTile(
                      leading: Icon(icon), 
                      title: Text(meal['details'] ?? ''),
                    );
                  }).toList(),
                )
              : const Text('Long press to set the meals for this day.'),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, bool>> getMealsForDay(DateTime day) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    Map<String, bool> meals = {
      'breakfast': false,
      'lunch': false,
      'dinner': false,
      'snack': false
    };
    if (uid == null) {
      Fluttertoast.showToast(msg: 'User not logged in');
      return meals;
    }
    final String formattedDate = DateFormat('yyyy-MM-dd').format(day);
    try {
      final dateRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dates')
          .where('date', isEqualTo: formattedDate)
          .limit(1);
      final dateSnapshot = await dateRef.get();
      if (dateSnapshot.docs.isNotEmpty) {
        final String dateId = dateSnapshot.docs.first.id;
        final metadataRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('metadata')
            .doc(dateId);
        final metadataSnapshot = await metadataRef.get();
        if (metadataSnapshot.exists) {
          final data = metadataSnapshot.data()!;
          meals['breakfast'] = data.containsKey('breakfast');
          meals['lunch'] = data.containsKey('lunch');
          meals['dinner'] = data.containsKey('dinner');
          meals['snack'] = data.containsKey('snack');
        }
      }
    } catch (e) {
      // Fluttertoast.showToast(msg: 'Error fetching meals for day: $e');
      print('Error fetching meals for day: $e');
    }
    return meals;
  }
}
