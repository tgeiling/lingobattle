import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'auth.dart';
import 'provider.dart';
import 'services.dart';

class SettingsPage extends StatelessWidget {
  final bool Function() isLoggedIn;
  final Function(bool) setAuthenticated;

  const SettingsPage({
    Key? key,
    required this.isLoggedIn,
    required this.setAuthenticated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (!isLoggedIn())
            _SettingsTile(
              title: 'Login',
              icon: Icons.login,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      setAuthenticated: setAuthenticated,
                    ),
                  ),
                );
              },
            ),
          if (isLoggedIn())
            _SettingsTile(
              title: 'Logout',
              icon: Icons.logout,
              onTap: () {
                final authService = AuthService();
                authService.logout();
                setAuthenticated(false);
              },
            ),
          _SettingsTile(
            title: 'Change Language',
            icon: Icons.language,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangeLanguagePage(),
                ),
              );
            },
          ),
          _SettingsTile(
            title: 'Terms and Conditions',
            icon: Icons.article,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TosWidgetPage(),
                ),
              );
            },
          ),
          _SettingsTile(
            title: 'Data Privacy',
            icon: Icons.privacy_tip,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataPrivacyPage(),
                ),
              );
            },
          ),
          _SettingsTile(
            title: 'Legal Notice (Impressum)',
            icon: Icons.privacy_tip,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImpressumPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 8,
          color: Colors.grey[200],
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.grey[600]),
          title: Text(
            title,
            style: const TextStyle(color: Colors.black),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class ChangeLanguagePage extends StatelessWidget {
  const ChangeLanguagePage({Key? key}) : super(key: key);

  final List<Map<String, String>> languages = const [
    {
      'name': 'English',
      'var': 'english',
      'code': 'en',
      'flag': 'assets/flags/english.png'
    },
    {
      'name': 'Deutsch',
      'var': 'german',
      'code': 'de',
      'flag': 'assets/flags/german.png'
    },
    {
      'name': 'Español',
      'var': 'spanish',
      'code': 'es',
      'flag': 'assets/flags/spanish.png'
    },
    {
      'name': 'Netherlands',
      'var': 'dutch',
      'code': 'it',
      'flag': 'assets/flags/dutch.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          AppLocalizations.of(context)!.changeLanguage,
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.selectYourLanguage,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final languageText = language['var']!;
                  String translatedLanguage;

                  switch (languageText) {
                    case "german":
                      translatedLanguage =
                          AppLocalizations.of(context)!.language_german;
                      break;
                    case "english":
                      translatedLanguage =
                          AppLocalizations.of(context)!.language_english;
                      break;
                    case "spanish":
                      translatedLanguage =
                          AppLocalizations.of(context)!.language_spanish;
                      break;
                    case "dutch":
                      translatedLanguage =
                          AppLocalizations.of(context)!.language_dutch;
                      break;
                    default:
                      translatedLanguage =
                          languageText; // Fallback in case of unexpected value
                  }
                  return GestureDetector(
                    onTap: () {
                      final profileProvider =
                          Provider.of<ProfileProvider>(context, listen: false);

                      profileProvider.setNativeLanguage(language['var']!);
                      getAuthToken().then((token) {
                        if (token != null) {
                          updateProfile(
                            token: token,
                            nativeLanguage: profileProvider.nativeLanguage,
                          ).then((success) {
                            if (success) {
                              print("Profile updated successfully.");
                            } else {
                              print("Failed to update profile.");
                            }
                          });
                        } else {
                          print("No auth token available.");
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: 6,
                        intensity: 0.6,
                        color: Colors.grey[300],
                        boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            language['flag']!,
                            width: 60,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            translatedLanguage,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TosWidgetPage extends StatelessWidget {
  const TosWidgetPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          AppLocalizations.of(context)!.termsOfService,
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            AppLocalizations.of(context)!.termsOfServiceText,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class DataPrivacyPage extends StatelessWidget {
  const DataPrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          AppLocalizations.of(context)!.dataPrivacyPolicy,
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            AppLocalizations.of(context)!.dataPrivacyPolicyText,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class ImpressumPage extends StatelessWidget {
  const ImpressumPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          AppLocalizations.of(context)!.impressum,
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            AppLocalizations.of(context)!.impressumText,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Text(title),
      ),
    );
  }
}
