import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
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
        title: const Text(
          'Change Language',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Select your language:',
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
                            language['name']!,
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
        title: const Text(
          "Terms of Service",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: const Text(
            "**Terms of Service**\n\n"
            "**Last Updated: [Date]**\n\n"
            "Welcome to Langobattle, operated by SKTG-Marketing (\"we,\" \"our,\" or \"us\"). By accessing or using our app, you agree to the following Terms of Service (\"ToS\"). If you do not agree, please do not use Langobattle.\n\n"
            "---\n\n"
            "### 1. General Information\n"
            "- App Name: Langobattle\n"
            "- Company: SKTG-Marketing\n"
            "- Website: https://sktg-marketing.de/\n\n"
            "---\n\n"
            "### 2. User Requirements & Eligibility\n"
            "- Langobattle is designed for all ages (4+).\n"
            "- Guest mode is available for solo play.\n"
            "- A registered username is required for duel mode.\n\n"
            "---\n\n"
            "### 3. User Accounts\n"
            "- Users create an account using a **username and password**.\n"
            "- Passwords must be **at least 6 characters** long.\n"
            "- Users may request **account deletion** by contacting us via email at **langobattle@outlook.com**.\n\n"
            "---\n\n"
            "### 4. User-Generated Content\n"
            "- Currently, users can create **usernames** only.\n"
            "- A **predefined character set** will be introduced (no free text for usernames).\n"
            "- A **word filter** is in place to prevent offensive usernames.\n"
            "- We reserve the right to **remove or modify usernames** that violate these rules.\n"
            "- If you encounter a violation, please report it via email.\n\n"
            "---\n\n"
            "### 5. Gameplay & Functionality\n"
            "- **Duel Mode**: Players are matched randomly and answer **5 questions**.\n"
            "- **ELO Rankings**: Winning increases ELO, losing decreases it.\n"
            "- **No in-app purchases** at this time.\n"
            "- **Rewards**: Players earn coins, which will be used in a **future avatar shop**.\n\n"
            "---\n\n"
            "### 6. Payments & Virtual Goods\n"
            "- Langobattle does not currently offer **in-app purchases**.\n"
            "- No **digital items** are sold or refundable.\n\n"
            "---\n\n"
            "### 7. Privacy & Data Collection\n"
            "- We collect **usernames and game statistics**.\n"
            "- We use **Google Cloud** for backend services.\n"
            "- Users can request **data deletion** via email at **langobattle@outlook.com**.\n\n"
            "---\n\n"
            "### 8. Prohibited Activities\n"
            "Users may not:\n"
            "- Use **bots, exploits, or cheats** (matchmaking and login protections are in place).\n"
            "- Create **offensive or impersonating usernames**.\n"
            "- Harass or engage in **hate speech** (word filter applied to usernames).\n"
            "- **Share accounts** (though this is currently allowed).\n\n"
            "---\n\n"
            "### 9. Liability & Disclaimers\n"
            "- Langobattle is developed by a solo developer and may contain **errors**.\n"
            "- We do not guarantee **uninterrupted service or data preservation**.\n"
            "- We are not liable for **lost in-game progress**.\n\n"
            "---\n\n"
            "### 10. Termination of Accounts\n"
            "- We reserve the right to **ban users** for violating these terms.\n"
            "- Banned users **cannot be contacted** by us.\n"
            "- Users may **appeal bans via email at langobattle@outlook.com**.\n\n"
            "---\n\n"
            "### 11. Governing Law & Jurisdiction\n"
            "- These Terms are governed by the **laws of Germany and the EU**.\n"
            "- Any disputes shall be resolved in accordance with applicable German and EU laws.\n\n"
            "---\n\n"
            "### 12. Changes to Terms\n"
            "- We may update these Terms at any time.\n"
            "- Continued use of the app means acceptance of the revised Terms.\n\n"
            "---\n\n"
            "For questions or support, please contact us at **langobattle@outlook.com**.",
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
        title: const Text(
          "Data Privacy Policy",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: const Text(
            "**Data Privacy Policy**\n\n"
            "**Last Updated: [Date]**\n\n"
            "Welcome to Langobattle. Your privacy is important to us. This policy explains how we collect, store, and use your data.\n\n"
            "---\n\n"
            "### 1. Data Collection\n"
            "- We collect: **usernames, game statistics**.\n"
            "- We do **not** collect: email, age, location, or sensitive personal data.\n\n"
            "---\n\n"
            "### 2. Data Storage & Security\n"
            "- Your data is stored on **Google Cloud servers**.\n"
            "- We use **secure authentication and encryption** where applicable.\n"
            "- User data is stored **until account deletion is requested**. Game statistics may be stored permanently.\n\n"
            "---\n\n"
            "### 3. Third-Party Services\n"
            "- We use **Google Cloud** for backend services.\n"
            "- We do **not** use Google Analytics, AdMob, or external tracking.\n"
            "- We do **not** share user data with third parties.\n\n"
            "---\n\n"
            "### 4. User Rights\n"
            "- Users can request **data deletion** via email at **langobattle@outlook.com**.\n"
            "- Usernames can be changed, but **game statistics cannot be reset**.\n\n"
            "---\n\n"
            "### 5. Cookies & Tracking\n"
            "- Langobattle **does not use cookies or third-party tracking technologies**.\n"
            "- We do **not track users outside of the app**.\n\n"
            "---\n\n"
            "### 6. Legal Compliance\n"
            "- We comply with **GDPR (EU privacy laws)** for data protection.\n"
            "- Our primary user base is within **Germany and the EU**.\n\n"
            "---\n\n"
            "For any privacy-related concerns, contact us at **langobattle@outlook.com**.",
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
        title: const Text(
          "Impressum",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: const Text(
            "**Impressum**\n\n"
            "**Angaben gemäß § 5 TMG:**\n\n"
            "sktg-marketing\n"
            "Timo Geiling\n"
            "Niederwöllstädter Str. 14\n"
            "61184 Karben\n\n"
            "**Kontakt:**\n"
            "Telefon: 0176 32141106\n"
            "E-Mail: timo.geiling@outlook.com\n\n"
            "**Umsatzsteuer:**\n"
            "Umsatzsteuer-Identifikationsnummer gemäß §27 a Umsatzsteuergesetz: DE368663332\n\n"
            "**Steuernummer:**\n"
            "1682063158\n\n"
            "Dieses Impressum gilt auch für die mobile App Langobattle.",
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
