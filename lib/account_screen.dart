import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
// import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_oauth_twitter/firebase_ui_oauth_twitter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:meal_planner_app/config.dart';
import 'package:meal_planner_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<Map<String, dynamic>> allDishes =
      []; 

  @override
  void initState() {
    super.initState();
    refreshAllDishes(); 
  }

  Future<void> refreshAllDishes() async {
    final uid = auth.FirebaseAuth.instance.currentUser!.uid;
    final dishes = await fetchAllDishes(uid);
    setState(() {
      allDishes = dishes; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final String uid = auth
        .FirebaseAuth.instance.currentUser!.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).canvasColor,
          elevation: 4.0,
          title: const Text('Account'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.food_bank), text: 'Summary'),
              Tab(icon: Icon(Icons.settings), text: 'Profile'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Summary Tab
            Center(
              child: Column(
                children: [
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchTopDishes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error: ${snapshot.error}"),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text("No dishes found."),
                          );
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final dish = snapshot.data![index];
                            return ListTile(
                              title: Text(dish['name']),
                              trailing: Text("Picked ${dish['count']} times"),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 8.0), 
                    child: ElevatedButton(
                      onPressed: () => showAllDishesDialog(context, uid),
                      child: const Icon(Icons.food_bank),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Account Tab
            ProfileScreen(
              providers: [
                EmailAuthProvider(),
                emailLinkProviderConfig,
                PhoneAuthProvider(),
                GoogleProvider(clientId: Config.googleClientId),
                AppleProvider(),
                // FacebookProvider(clientId: Config.facebookClientId),
                TwitterProvider(
                  apiKey: Config.twitterApiKey,
                  apiSecretKey: Config.twitterApiSecretKey,
                  redirectUri: Config.twitterRedirectUri,
                ),
              ],
              actions: [
                SignedOutAction((context) {
                  Navigator.pushReplacementNamed(context, '/');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showAllDishesDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("All Dishes"),
              content: allDishes.isEmpty
                  ? const Text("No dishes found.")
                  : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allDishes.length,
                        itemBuilder: (context, index) {
                          final dish = allDishes[index];
                          return ListTile(
                            title: Text(dish['name']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                bool deleted =
                                    await deleteDish(dish['id'], context);
                                if (deleted) {
                                  await refreshAllDishes();
                                  setState(() {
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchTopDishes() async {
    final String? uid = auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Gebruiker niet ingelogd");

    final meals = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meals')
        .get();
    // print('Fetched ${meals.docs.length} meals');
    // meals.docs.forEach((doc) => print('Meal: ${doc.id}, Data: ${doc.data()}'));

    final metadata = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('metadata')
        .get();
    // print('Fetched ${metadata.docs.length} metadata');
    // metadata.docs.forEach((doc) => print('Metadata: ${doc.id}, Data: ${doc.data()}'));

    final Map<String, int> mealCountMap = {};

    for (var doc in metadata.docs) {
      final data = doc.data();
      ['breakfast', 'lunch', 'dinner', 'snack'].forEach((mealType) {
        final mealId = data[mealType];
        if (mealId != null) {
          mealCountMap[mealId] = (mealCountMap[mealId] ?? 0) + 1;
        }
      });
    }

    // print('mealCountMap: $mealCountMap');
    // I/flutter (31195): mealCountMap: {uMNQQWT8Rx8du2dAL4Pa: 1, rEmmlHFWW3Yc0bQHyeJi: 7, eS2ND7u200JMTvvEdOqC: 5, r4L8eeOmHfImhyUmb3Ly: 2, 29ER0LlDDRUzfxvtDJim: 4, Lf2onri85ov9ECh3ICa7: 3, sLRExGn7bk7DKWPg2PYJ: 3, QQ2INTxjFisRTmREet8f: 3, EvfFd6Pp8iN7qLsZbjkg: 1, euePdgZf7sfmi3ARJRTe: 2, 22QTmkrQju89ke6YTCTa: 3, M9OEuOIN4j6QFl7wOrDg: 2, 9Ct8k5IKa8Qex9122DbE: 1, jCn4MtMmAEzl62JzdY33: 1, aHt19PuuMhYvWfKMJDn3: 1}

    final Map<String, Map<String, dynamic>> mealNameCountMap = {};

    for (var doc in meals.docs) {
      final data = doc.data();
      final mealId = doc.id;
      final mealName = data['name'];
      final mealCount = mealCountMap[mealId] ?? 0;
      mealNameCountMap[mealId] = {
        'name': mealName,
        'count': mealCount,
      };
    }

    // print('mealNameCountMap: $mealNameCountMap');

    final sortedMeals = mealNameCountMap.values.toList()
      ..sort((a, b) => b['count'].compareTo(a['count']));

    return sortedMeals;
  }

// Fetch all dishes
  Future<List<Map<String, dynamic>>> fetchAllDishes(String uid) async {
    final String? uid = auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Gebruiker niet ingelogd");
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meals')
        .get();
    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

// Delete a specific dish
  Future<bool> deleteDish(String dishId, BuildContext context) async {
    try {
      final String? uid = auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(dishId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dish deleted successfully')),
      );
      return true; 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete dish: ${e.toString()}')),
      );
      return false; 
    }
  }
}
