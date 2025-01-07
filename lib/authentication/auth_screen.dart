
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orderapp/authentication/email_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orderapp/widgets/navigation_bar.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import '../global/global.dart';
import '../widgets/error_dialog.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

class MergedLoginScreen extends StatefulWidget {
  const MergedLoginScreen({Key? key}) : super(key: key);

  @override
  _MergedLoginScreenState createState() => _MergedLoginScreenState();
}

class _MergedLoginScreenState extends State<MergedLoginScreen> {


  Future<void> appleSign() async {
    AuthorizationResult authorizationResult =
    await TheAppleSignIn.performRequests([
      const AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);

    switch (authorizationResult.status) {
      case AuthorizationStatus.authorized:
        print("authorized");
        try {
          AppleIdCredential? appleCredentials =
              authorizationResult.credential;
          OAuthProvider oAuthProvider = OAuthProvider("apple.com");
          OAuthCredential oAuthCredential = oAuthProvider.credential(
            idToken: String.fromCharCodes(appleCredentials!.identityToken!),
            accessToken:
            String.fromCharCodes(appleCredentials.authorizationCode!),
          );

          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithCredential(oAuthCredential);
          if (userCredential.user != null) {
            String uid = userCredential.user?.uid ?? "";
            String userEmail = userCredential.user?.email ?? "";
            bool trackingPermissionStatus =
                sharedPreferences!.getBool("tracking") ?? false;

            DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .get();

            if (!userSnapshot.exists) {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .set({
                "uid": uid,
                "address": "Add Location",
                "status": "approved",
                "email": userCredential.user!.email,
                "name": "Add Full Name",
                "phone": "Add Phone Number",
                "trackingPermission": trackingPermissionStatus,
              });
            }

            await readDataAndSetDataLocally(userCredential.user!);
          }
        } catch (e) {
          print("Apple auth failed $e");
        }

        break;
      case AuthorizationStatus.error:
        print("error" + authorizationResult.error.toString());
        break;
      case AuthorizationStatus.cancelled:
        print("cancelled");
        break;
      default:
        print("none of the above: default");
        break;
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential authResult =
        await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null) {
          String uid = user.uid;
          String userEmail = user.email ?? "";
          String userName = user.displayName ?? "";

          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .get();

          if (!userSnapshot.exists) {
            bool trackingPermissionStatus =
                sharedPreferences!.getBool("tracking") ?? false;

            FirebaseFirestore.instance.collection("userrs").doc(uid).set({
              "uid": uid,
              "email": userEmail,
              "name": userName,
              "phone": "Add Phone Number",
              "address": "Add Location",
              "status": "approved",
              "trackingPermission": trackingPermissionStatus,
            });
          }

          readDataAndSetDataLocally(user);
        }
      }
    } catch (error) {
      print("Google Sign-In Error: $error");
    }
  }

  Future readDataAndSetDataLocally(User currentUser) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get()
        .then((snapshot) async {
      if (snapshot.exists) {

          await sharedPreferences!.setString("uid", currentUser.uid);
          await sharedPreferences!.setString(
              "email", snapshot.data()!["email"]);
          await sharedPreferences!.setString("name", snapshot.data()!["name"]);
          await sharedPreferences!.setString(
              "phone", snapshot.data()!["phone"]);
          await sharedPreferences!.setString(
              "address", snapshot.data()!["address"]);



          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => NavigationPage()));
        } else {
        _auth.signOut();
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (c) => const MergedLoginScreen()));

        showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(
              message: "No record found.",
            );
          },
        );
      }
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image(
                image: NetworkImage(
                  "https://cdn3.iconfinder.com/data/icons/network-and-communications-6/130/291-128.png",
                ),
                height: 90,
                width: 90,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 30),
                child: Text(
                  "Sign In",
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.normal,
                    fontSize: 20,
                    color: Color(0xff3a57e8),
                  ),
                ),
              ),
              if (Platform.isIOS) // Check if the platform is iOS
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0), // Adjust padding here
                  child: OutlinedButton(
                    onPressed: () {
                      appleSign();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue with Apple",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Image.asset(
                          'images/apple.png',
                          width: 50,
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ),

              if (Platform.isAndroid) // Check if the platform is iOS
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          _signInWithGoogle();
                        },
                        style: OutlinedButton.styleFrom( // Text color
                          side: BorderSide(color: Colors.black), // Border color
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 14,
                                color: Colors.black, // Text color
                              ),
                            ),
                            SizedBox(width: 8), // Add some spacing between the text and the icon
                            Image.asset(
                              'images/google.png', // Add the path to your Google logo image
                              width: 50,
                              height: 50,
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),

              if (Platform.isIOS || Platform.isAndroid) // Check if the platform is iOS or Android
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EmailLoginScreen()));
                      // Add your logic for signing in with email here
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue with Email",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.email, // You can use any email-related icon here
                          color: Colors.black, // Icon color
                          size: 24,
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