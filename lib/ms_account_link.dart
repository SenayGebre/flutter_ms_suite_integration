// lib/screens/auth/ms_account_link_screen.dart
import 'package:flutter/material.dart';
import 'package:ms_suite/login.dart';
import 'package:ms_suite/ms_auth_service.dart';
import 'package:universal_html/html.dart' as html;

class MSAccountLinkScreen extends StatefulWidget {
  @override
  _MSAccountLinkScreenState createState() => _MSAccountLinkScreenState();
}

class _MSAccountLinkScreenState extends State<MSAccountLinkScreen> {
  final MSAuthService _msAuth = MSAuthService();
  final CustomAuthService _customAuth = CustomAuthService();
  bool _isLinking = false;
  bool _checkingExistingLink = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    var uri = Uri.parse(html.window.location.href);
    print(uri);
    // _checkExistingLink();
  }

  Future<void> _checkExistingLink() async {
    try {
      final isValid = await _msAuth.isTokenValid();
      if (isValid) {
        _navigateToMeetingScreen();
      }
    } catch (e) {
      print('Error checking existing link: $e');
    } finally {
      setState(() {
        _checkingExistingLink = false;
      });
    }
  }

  Future<void> _linkMicrosoftAccount() async {
    setState(() {
      _isLinking = true;
      _errorMessage = null;
    });

    try {
      final success = await _msAuth.linkMicrosoftAccount();

      if (success && mounted) {
        final profile = _msAuth.userProfile;
        if (profile != null) {
          _navigateToMeetingScreen();
        } else {
          throw MSAuthException('Failed to get user profile');
        }
      }
    } on MSAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLinking = false;
        });
      }
    }
  }

  void _navigateToMeetingScreen() {
    Navigator.of(context).pushReplacementNamed('/create-meeting');
  }

  Future<void> _skipLinking() async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Skip Microsoft Account'),
          content: Text(
              'Without linking your Microsoft account, you won\'t be able to:\n\n'
              '• Schedule committee meetings\n'
              '• Access meeting rooms\n'
              '• Send meeting invitations\n\n'
              'Do you want to proceed without linking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Proceed without linking'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        );
      },
    );

    if (proceed == true) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (_checkingExistingLink) {
    //   return Scaffold(
    //     body: Center(
    //       child: CircularProgressIndicator(),
    //     ),
    //   );
    // }

    final user = _customAuth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Microsoft Account'),
        actions: [
          if (!_isLinking)
            TextButton(
              onPressed: _skipLinking,
              child: Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.abc,
                  size: 40,
                  color: theme.primaryColor,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Welcome ${user?.name ?? ""}!',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Link your Microsoft account to enable committee meeting scheduling',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLinking ? null : _linkMicrosoftAccount,
                icon: Icon(Icons.abc),
                label:
                    Text(_isLinking ? 'Linking...' : 'Link Microsoft Account'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: theme.primaryColor.withOpacity(0.6),
                ),
              ),
              if (_isLinking) ...[
                SizedBox(height: 16),
                LinearProgressIndicator(),
              ],
              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 32),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What you can do after linking:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 16),
                      _FeatureItem(
                        icon: Icons.groups_outlined,
                        title: 'Access Committee Information',
                        description: 'View and manage committee details',
                      ),
                      _FeatureItem(
                        icon: Icons.calendar_month_outlined,
                        title: 'Schedule Meetings',
                        description: 'Create and manage committee meetings',
                      ),
                      _FeatureItem(
                        icon: Icons.meeting_room_outlined,
                        title: 'Book Meeting Rooms',
                        description: 'Reserve rooms for your meetings',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
