
import 'package:flutter/material.dart';
import 'package:orderapp/authentication/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orderapp/mainScreens/chat_screen.dart';
import 'package:orderapp/mainScreens/notification.dart';
import 'package:orderapp/mainScreens/settings_screen.dart';
import 'package:orderapp/widgets/qr_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MergedLoginScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          SizedBox(height: 22.0),
          Image.asset(
            "images/image.png",
            width: 400.0,
            height: 250.0,
          ),
          SizedBox(height: 20),


          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.black),
            title: const Text(
              "My Profile",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => MySettings()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notification_add_outlined, color: Colors.black),
            title: const Text(
              "Notifications",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => NotificationScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.black),
            title: const Text(
              "QR Code",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) =>YourScreen()),
              );
            },
          ),


          ListTile(
            leading: const Icon(Icons.language, color: Colors.black),
            title: const Text(
              "Language: English",
              style: TextStyle(color: Colors.black),
            ),
          ),

          const Divider(
            height: 10,
            color: Colors.grey,
            thickness: 2,
          ),

          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.black),
            title: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              signOutAndClearPrefs(context);
            },
          ),


        ],
      ),
    );
  }
}
