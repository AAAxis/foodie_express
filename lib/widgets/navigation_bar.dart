import 'package:orderapp/authentication/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:orderapp/mainScreens/account.dart';
import 'package:orderapp/mainScreens/chat_screen.dart';
import 'package:orderapp/mainScreens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationPage extends StatefulWidget {
  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _currentIndex = 0;
  bool _isLoggedIn = false; // Initialize as not logged in

  final List<Widget> _screens = [
    HomeScreen(),
    ChatScreen(),
    AccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    checkLoggedInStatus(); // Check the login status when the widget initializes
  }

  // Function to check login status
  void checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Check if "user_email" is present in SharedPreferences
      _isLoggedIn = prefs.getString('email') != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(

        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.black, // Set icon color to black
          onTap: (index) {
            if (index == 2 && !_isLoggedIn) {
              // If "Login" button is tapped and not logged in, navigate to AuthScreen
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => MergedLoginScreen(),
              ));
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed, // Fixed type to center icons
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.food_bank_outlined, size: 35), // Increase icon size
              label: 'Eats', // Label text
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.chat, size: 35), // Car icon
              label: 'Chat', // Label text
            ),


            BottomNavigationBarItem(
              icon: _isLoggedIn
                  ? Icon(Icons.person, size: 35) // Display user icon if logged in
                  : Icon(Icons.login, size: 35), // Display login icon if not logged in
              label: _isLoggedIn ? 'Account' : 'Login', // Label text
            ),
          ],
        ),
      );

  }
}
