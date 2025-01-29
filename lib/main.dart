// lib/main.dart updates
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ms_suite/create_meeting_screen.dart';
import 'package:ms_suite/login.dart';
import 'package:ms_suite/ms_account_link.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:ms_suite/oauth_call_back_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();
void main() {
  // setUrlStrategy(PathUrlStrategy());
  // usePathUrlStrategy();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/ms-link',
        builder: (context, state) => MSAccountLinkScreen(),
      ),
      GoRoute(
        path: '/create-meeting',
        builder: (context, state) => CreateMeetingScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: _router.routerDelegate,
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _router.routeInformationProvider,
      title: 'Bank Meeting Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // routes: {
      //   '/': (context) => LoginScreen(),
      //   '/ms-link': (context) => MSAccountLinkScreen(),
      //   '/callback': (context) => OAuthCallbackScreen(),
      //   '/create-meeting': (context) =>
      //       CreateMeetingScreen(), // We'll create this next
      // },
    );
  }
}
