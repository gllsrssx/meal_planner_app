import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FamilySharingScreen extends StatelessWidget {
  final String userId;

  const FamilySharingScreen(this.userId, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deel met gezin'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Implementeer de logica om een gezinslid toe te voegen.
            },
            child: const Text('Voeg gezinslid toe'),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('family')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var familyMembers = snapshot.data?.docs;
                return ListView.builder(
                  itemCount: familyMembers?.length,
                  itemBuilder: (context, index) {
                    var member = familyMembers?[index];
                    return ListTile(
                      title: Text(member?['name']),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
