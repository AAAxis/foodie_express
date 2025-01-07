import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orderapp/widgets/navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global/global.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; // Initialize Firebase Auth

  void _navigateToHomeScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (c) => NavigationPage()));
  }

  void _requestPermissionManually() async {
    final trackingStatus = await AppTrackingTransparency.requestTrackingAuthorization();
    print('Manual tracking permission request status: $trackingStatus');

    final prefs = await SharedPreferences.getInstance();

    if (trackingStatus == TrackingStatus.authorized) {
      // User granted permission
      await prefs.setBool('trackingPermissionStatus', true);
    } else {
      // User denied permission or not determined, store it as false
      await prefs.setBool('trackingPermissionStatus', false);
    }

    // Continue with your application flow after checking tracking permission
    _navigateToHomeScreen();
  }

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 3), () async {
      if (firebaseAuth.currentUser != null) {
        _navigateToHomeScreen();
      } else {
        print('Waiting for response');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (_) {
        // Handle vertical swipe to continue
        _requestPermissionManually();
      },
      child: Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100.0),
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Image.asset("images/splash.png"),
                  ),
                ),
                const SizedBox(height: 30,),
                Text(
                  "Swipe to Continue >>",
                  style: TextStyle(
                    color: Colors.black, // Change the color to your preference
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
