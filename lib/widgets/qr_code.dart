import 'package:flutter/material.dart';
import 'package:order_app/widgets/navigation_bar.dart';


class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Information'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => NavigationPage()),
            );
          },
        ),
      ),
      body: Center(
        child: Image.network(
          'https://polskoydm.pythonanywhere.com/static/qrcode_theholylabs.com.png',
          width: 300, // Adjust width as needed
          height: 300, // Adjust height as needed
        ),
      ),
    );
  }
}
