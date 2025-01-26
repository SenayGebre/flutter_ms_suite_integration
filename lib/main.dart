// lib/main.dart updates
import 'package:flutter/material.dart';
import 'package:ms_suite/create_meeting_screen.dart';
import 'package:ms_suite/login.dart';
import 'package:ms_suite/ms_account_link.dart';

final navigatorKey = GlobalKey<NavigatorState>();
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Bank Meeting Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => LoginScreen(),
        '/ms-link': (context) => MSAccountLinkScreen(),
        '/create-meeting': (context) =>
            CreateMeetingScreen(), // We'll create this next
      },
    );
  }
}
