import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orderapp/widgets/navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../global/global.dart';
import '../widgets/error_dialog.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({Key? key}) : super(key: key);

  @override
  _EmailLoginScreenState createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final List<TextEditingController> codeControllers = List.generate(6, (index) => TextEditingController());

  bool _isEmailSent = false;
  String? verificationCode;

  Future<void> sendEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !isValidEmail(email)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Invalid Email'),
            content: const Text('Please enter a valid email address.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://polskoydm.pythonanywhere.com/global_auth?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _isEmailSent = true;
          verificationCode = data['verification_code'];
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Failed to Send Email'),
              content: const Text('Unable to send email. Please try again later.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred while sending the email: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegex.hasMatch(email);
  }

  void verify() async {
    final enteredCode = codeControllers.map((controller) => controller.text).join('');
    bool trackingPermissionStatus = sharedPreferences!.getBool("tracking") ?? false;

    if (enteredCode == verificationCode) {
      final email = emailController.text.trim();
      const password = "passwordless";

      try {
        UserCredential userCredential;

        // Attempt to create a user account
        try {
          userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          String uid = userCredential.user?.uid ?? "";
          String userEmail = userCredential.user?.email ?? "";

          // Check if the user exists in Firestore
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .get();

          if (!userSnapshot.exists) {
            // If the user doesn't exist in Firestore, create a new document
            await FirebaseFirestore.instance.collection("users").doc(uid).set({
              "uid": uid,
              "name": "Add Full Name",
              "phone": "Add Phone Number",
              "email": userEmail,
              "address": "Add Location",
              "status": "approved",
              "trackingPermission": trackingPermissionStatus,
            });

            final SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString("email", userEmail);
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Verification Successful'),
                  content: const Text('You have successfully verified your email.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        readDataAndSetDataLocally(userCredential.user!);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }

        } catch (e) {
          if (e is FirebaseAuthException) {
            if (e.code == 'email-already-in-use') {
              try {
                userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                if (userCredential.user != null) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Verification Successful'),
                        content: const Text('You have successfully verified your email.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              readDataAndSetDataLocally(userCredential.user!);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              } catch (e) {
                print('Failed to sign in the user: $e');
              }
            } else {
              print('Failed to create a user account: $e');
            }
          }
        }
      } catch (e) {
        print('Error: $e');
      }
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Verification Failed'),
            content: const Text('Invalid verification code. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
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
        await sharedPreferences!.setString("email", snapshot.data()!["email"]);
        await sharedPreferences!.setString("name", snapshot.data()!["name"]);
        await sharedPreferences!.setString("address", snapshot.data()!["address"]);
        await sharedPreferences!.setString("phone", snapshot.data()!["phone"]);

        Navigator.pop(context);
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => NavigationPage()));
      } else {
        _auth.signOut();
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (c) => const EmailLoginScreen()));

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
      backgroundColor: const Color(0xffffffff),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Image(
                image: NetworkImage(
                  "https://cdn3.iconfinder.com/data/icons/network-and-communications-6/130/291-128.png",
                ),
                height: 90,
                width: 90,
                fit: BoxFit.cover,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 30),
                child: Text(
                  "Sign In",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xff3a57e8),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Text(
                  "Continue with Email",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xff9e9e9e),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Visibility(
                  visible: !_isEmailSent,
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: _isEmailSent
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 40,
                      child: TextField(
                        controller: codeControllers[index],
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          counterText: '',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.length == 1) {
                            // Move focus to the next field
                            if (index < 5) {
                              FocusScope.of(context).nextFocus();
                            } else {
                              // Check if all fields have values
                              String enteredCode = codeControllers.map((controller) => controller.text).join('');
                              if (enteredCode.length == 6) {
                                verify(); // Auto submit when 6 digits are entered
                              }
                            }
                          }
                        },
                      ),
                    );
                  }),
                )
                    : Container(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: OutlinedButton(
                  onPressed: _isEmailSent ? verify : sendEmail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black, side: const BorderSide(color: Colors.black), // Text color
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32), // Padding for the button
                  ),
                  child: Text(_isEmailSent ? 'Submit' : 'Send Code'),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
