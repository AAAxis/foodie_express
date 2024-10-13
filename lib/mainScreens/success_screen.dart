import 'package:flutter/material.dart';
import 'package:orderapp/widgets/navigation_bar.dart';

class SuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your order has been placed successfully!'),
            SizedBox(height: 20), // Add some spacing
            ElevatedButton(
              onPressed: () {
                // Navigate back to the home page when the button is pressed
                Navigator.push(context,
                    MaterialPageRoute(builder: (c) => NavigationPage()));

              },
              child: Text('Back Home'),
            ),
          ],
        ),
      ),
    );
  }
}
