import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_oauth_twitter/firebase_ui_oauth_twitter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:meal_planner_app/config.dart';
import 'package:meal_planner_app/main.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
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
            // Profile Tab
            const Center(
              child: Text('Hello'),
            ),
            // Account Tab
            ProfileScreen(
              providers: [
                EmailAuthProvider(),
                emailLinkProviderConfig,
                PhoneAuthProvider(),
                GoogleProvider(clientId: Config.googleClientId),
                AppleProvider(),
                FacebookProvider(clientId: Config.facebookClientId),
                TwitterProvider(
                  apiKey: Config.twitterApiKey,
                  apiSecretKey: Config.twitterApiSecretKey,
                  redirectUri: Config.twitterRedirectUri,
                ),
              ],
              actions: [
                SignedOutAction((context) {
                  // FirebaseUIAuth.signOut(context: context);
                  Navigator.pushReplacementNamed(context, '/sign-in');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
