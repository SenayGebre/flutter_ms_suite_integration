import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class OAuthCallbackScreen extends StatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var urii = Uri.parse(html.window.location.href);
    print(urii);

    // Listen for postMessage events
    html.window.onMessage.listen((event) {
      try {
        // Parse the message
        final message = jsonDecode(event.data);

        if (message['type'] == 'oauthCallback') {
          final String? code = message['code'];
          final String? state = message['state'];

          if (code != null) {
            print('Authorization Code: $code');
            // Perform token exchange or navigate to another screen
          } else {
            print('Authorization Code not found in the callback');
          }
        }
      } catch (e) {
        print('Error parsing callback message: $e');
      }
    });

    // Fallback: Read query parameters directly from the URL
    final uri = Uri.parse(html.window.location.href);
    print('Full Callback URI: $uri');
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
