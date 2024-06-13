import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_oauth_twitter/firebase_ui_oauth_twitter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:meal_planner_app/account_screen.dart';
import 'package:meal_planner_app/day_detail.dart';
import 'package:meal_planner_app/Home_screen.dart';
import 'package:meal_planner_app/week_overview.dart';

import 'config.dart';
// import 'decorations.dart';
import 'firebase_options.dart';

final actionCodeSettings = ActionCodeSettings(
  url: 'flutter-b2483.firebaseapp.com',
  handleCodeInApp: true,
  androidMinimumVersion: '1',
  androidPackageName: 'io.flutter.plugins.firebase_ui.firebase_ui',
  iOSBundleId: 'io.flutter.plugins.firebaseUi',
);
final emailLinkProviderConfig = EmailLinkAuthProvider(
  actionCodeSettings: actionCodeSettings,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

  FirebaseUIAuth.configureProviders([
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
  ]);

  runApp(const FirebaseAuthUI());
}

class LabelOverrides extends DefaultLocalizations {
  const LabelOverrides();

  @override
  String get emailInputLabel => 'Enter your email';
}

class FirebaseAuthUI extends StatelessWidget {
  const FirebaseAuthUI({super.key});

  String get initialRoute {
    final user = FirebaseAuth.instance.currentUser;

    return switch (user) {
      null => '/',
      User(emailVerified: false, email: final String _) => '/verify-email',
      _ => '/Home',
    };
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    final mfaAction = AuthStateChangeAction<MFARequired>(
      (context, state) async {
        final nav = Navigator.of(context);

        await startMFAVerification(
          resolver: state.resolver,
          context: context,
        );

        nav.pushReplacementNamed('/Home');
      },
    );

    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        visualDensity: VisualDensity.standard,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
        textButtonTheme: TextButtonThemeData(style: buttonStyle),
        outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => SignInScreen(
              actions: [
                ForgotPasswordAction((context, email) {
                  Navigator.pushNamed(
                    context,
                    '/forgot-password',
                    arguments: {'email': email},
                  );
                }),
                VerifyPhoneAction((context, _) {
                  Navigator.pushNamed(context, '/phone');
                }),
                AuthStateChangeAction((context, state) {
                  final user = switch (state) {
                    SignedIn(user: final user) => user,
                    CredentialLinked(user: final user) => user,
                    UserCreated(credential: final cred) => cred.user,
                    _ => null,
                  };

                  switch (user) {
                    case User(emailVerified: true):
                      Navigator.pushReplacementNamed(context, '/Home');
                    case User(emailVerified: false, email: final String _):
                      Navigator.pushNamed(context, '/verify-email');
                  }
                }),
                mfaAction,
                EmailLinkSignInAction((context) {
                  Navigator.pushReplacementNamed(
                      context, '/email-link-sign-in');
                }),
              ],
              styles: const {
                EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
              },
              // headerBuilder: headerImage('assets/images/flutterfire_logo.png'),
              // sideBuilder: sideImage('assets/images/flutterfire_logo.png'),
              subtitleBuilder: (context, action) {
                final actionText = switch (action) {
                  AuthAction.signIn => 'Please sign in to continue.',
                  AuthAction.signUp => 'Please create an account to continue',
                  _ => throw Exception('Invalid action: $action'),
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Welcome to Firebase UI! $actionText.'),
                );
              },
              footerBuilder: (context, action) {
                final actionText = switch (action) {
                  AuthAction.signIn => 'signing in',
                  AuthAction.signUp => 'registering',
                  _ => throw Exception('Invalid action: $action'),
                };

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'By $actionText, you agree to our terms and conditions.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),

        '/Home': (context) => const HomeScreen(),
        '/Account': (context) => const AccountScreen(),
        '/week_overview': (context) => WeekOverview(startDate: DateTime.now()),
        '/day_detail': (context) => DayDetail(date: DateTime.now()),

        '/verify-email': (context) =>
            const HomeScreen(), // EmailVerificationScreen(
        // headerBuilder: headerIcon(Icons.verified),
        // sideBuilder: sideIcon(Icons.verified),
        //   actionCodeSettings: actionCodeSettings,
        //   actions: [
        //     EmailVerifiedAction(() {
        //       Navigator.pushReplacementNamed(context, '/Home');
        //     }),
        //     AuthCancelledAction((context) {
        //       FirebaseUIAuth.signOut(context: context);
        //       Navigator.pushReplacementNamed(context, '/');
        //     }),
        //   ],
        // ),
        '/phone': (context) => PhoneInputScreen(
              actions: [
                SMSCodeRequestedAction((context, action, flowKey, phone) {
                  Navigator.of(context).pushReplacementNamed(
                    '/sms',
                    arguments: {
                      'action': action,
                      'flowKey': flowKey,
                      'phone': phone,
                    },
                  );
                }),
              ],
              // headerBuilder: headerIcon(Icons.phone),
              // sideBuilder: sideIcon(Icons.phone),
            ),
        '/sms': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return SMSCodeInputScreen(
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.of(context).pushReplacementNamed('/Home');
              })
            ],
            flowKey: arguments?['flowKey'],
            action: arguments?['action'],
            // headerBuilder: headerIcon(Icons.sms_outlined),
            // sideBuilder: sideIcon(Icons.sms_outlined),
          );
        },
        '/forgot-password': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return ForgotPasswordScreen(
            email: arguments?['email'],
            headerMaxExtent: 200,
            // headerBuilder: headerIcon(Icons.lock),
            // sideBuilder: sideIcon(Icons.lock),
          );
        },
        '/email-link-sign-in': (context) => EmailLinkSignInScreen(
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  Navigator.pushReplacementNamed(context, '/');
                }),
              ],
              provider: emailLinkProviderConfig,
              headerMaxExtent: 200,
              // headerBuilder: headerIcon(Icons.link),
              // sideBuilder: sideIcon(Icons.link),
            ),
        '/Profile': (context) => ProfileScreen(
              actions: [
                SignedOutAction((context) {
                  FirebaseUIAuth.signOut(context: context);
                  Navigator.pushReplacementNamed(context, '/');
                }),
                mfaAction,
              ],
              actionCodeSettings: actionCodeSettings,
              showMFATile: kIsWeb ||
                  Theme.of(context).platform == TargetPlatform.iOS ||
                  Theme.of(context).platform == TargetPlatform.android,
              showUnlinkConfirmationDialog: true,
              showDeleteConfirmationDialog: true,
            ),
      },
      title: 'Firebase UI Auth',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: [
        FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FirebaseUILocalizations.delegate,
      ],
    );
  }
}
