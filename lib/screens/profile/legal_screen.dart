import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

const _privacy = '''
Last updated: November 2026

GrubOut ("we") respects your privacy. This policy explains what the app does with your information.

1. Data you enter
Your account (name, email, password), body profile (age, sex, height, weight, goals) and every food, exercise, water, weight and fasting entry are stored only on your device in a local database. We do not run servers that receive this data, and we do not sell or share it.

2. Passwords
Passwords are never stored in plain text. They are salted and hashed on your device.

3. Food searches and barcodes
When you search for a food or scan a barcode, the search text or barcode number is sent to public nutrition databases (USDA FoodData Central and Open Food Facts) to fetch nutrition information. Recipe browsing loads data and images from TheMealDB. These requests do not include your name, email or diary.

4. Camera and microphone
The camera is used only to scan barcodes while the scanner is open. The microphone and speech recognition are used only when you tap the microphone to search by voice. Nothing is recorded or stored.

5. Notifications
Reminders are scheduled locally on your device and can be turned off any time in Settings.

6. Purchases
Subscriptions are processed by Apple (App Store) or Google (Play Store). We never see your payment details.

7. Deleting your data
Profile → Settings → Delete account permanently erases your account and all of its data from this device. Uninstalling the app also removes all data.

8. Children
GrubOut is not intended for children under 13.

9. Health disclaimer
GrubOut provides general nutrition estimates and is not a medical device or a substitute for professional advice.

10. Contact
Questions? Email support@grubout.app.
''';

const _terms = '''
Last updated: November 2026

By using GrubOut you agree to these terms.

1. Not medical advice
Calorie, macro and weight estimates are for general information only. Consult a qualified health professional before starting a diet, fasting or exercise programme, especially if you are pregnant, nursing, under 18, or have a medical condition.

2. Your account
You are responsible for keeping your device and password secure. Your data lives on your device; we cannot recover it if the app is deleted.

3. Premium subscriptions
GrubOut Premium is an auto-renewing subscription. Payment is charged to your App Store / Play Store account at confirmation of purchase. It renews automatically unless cancelled at least 24 hours before the end of the current period. You can manage or cancel in your store account settings. Unused portions of a free trial are forfeited when you purchase a subscription.

4. Third-party data
Nutrition data comes from USDA FoodData Central, Open Food Facts and our own Filipino food list. It may contain errors; always check labels when accuracy matters.

5. Acceptable use
Do not misuse the app, attempt to reverse engineer it, or use it for unlawful purposes.

6. Changes
We may update these terms. Continued use after an update means you accept the new terms.

7. Contact
support@grubout.app
''';

class LegalScreen extends StatelessWidget {
  final String title;
  final String body;

  const LegalScreen.privacy({super.key})
      : title = 'Privacy Policy',
        body = _privacy;

  const LegalScreen.terms({super.key})
      : title = 'Terms of Use',
        body = _terms;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              Text(body.trim(), style: TextStyle(height: 1.55, fontSize: 15, color: context.colors.text)),
            ],
          ),
        ),
      );
}
