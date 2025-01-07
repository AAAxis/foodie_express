import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orderapp/widgets/navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart'; // Import your settings screen file
import 'package:http/http.dart' as http;
import 'dart:convert';

class CartPage extends StatefulWidget {
  final String storeId;
  final Map<String, int> cartItems;

  CartPage({required this.storeId, required this.cartItems});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<Map<String, dynamic>> _merchantAndProductFuture;
  late Map<String, dynamic> productsData; // Define productsData here

  @override
  void initState() {
    super.initState();
    _merchantAndProductFuture = fetchMerchantAndProductDetails().then((value) {
      setState(() {
        productsData = value['productsData'];
      });
      return value;
    });
  }

  // Other methods...

  int calculateTotalPrice() {
    if (productsData.isEmpty) {
      return 0; // or handle the case when productsData is empty
    }

    int total = 0;

    widget.cartItems.forEach((productId, quantity) {
      final productData = productsData[productId] as Map<String, dynamic>;
      final price = (productData['price'] as double).toInt();
      total += price * quantity;
    });

    return total;
  }


  Future<Map<String, dynamic>> fetchMerchantAndProductDetails() async {
    DocumentSnapshot merchantSnapshot =
    await FirebaseFirestore.instance.collection('merchants').doc(widget.storeId).get();
    Map<String, dynamic> merchantData = merchantSnapshot.data() as Map<String, dynamic>;

    QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
        .collection('merchants')
        .doc(widget.storeId)
        .collection('products')
        .get();
    Map<String, dynamic> productsData = {};

    productsSnapshot.docs.forEach((productDoc) {
      productsData[productDoc.id] = productDoc.data();
    });

    return {
      'merchantData': merchantData,
      'productsData': productsData,
    };
  }




  Future<void> _submitOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    final phone = prefs.getString('phone');
    final address = prefs.getString('address');

    if (name == null || name == 'Add Full Name' ||
        phone == null || phone == 'Add Phone Number' ||
        address == null || address == 'Add Location') {
      // Show a snackbar prompting the user to set their information
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please set your name, phone, and address in settings.'),
          action: SnackBarAction(
            label: 'Go to Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MySettings()),
              );
            },
          ),
        ),
      );
    } else {
      final cartItems = widget.cartItems;
      final totalPrice = calculateTotalPrice();
      final storeId = widget.storeId;

      // Save the order to Firestore
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'email': prefs.getString('email'),
        'name': name,
        'phone': phone,
        'address': address,
        'timestamp': Timestamp.now(),
        'total': totalPrice,
        'store': storeId,
        'status': 'ordering',
      });

      // Add cart items as a subcollection
      cartItems.forEach((productId, quantity) async {
        final productData = productsData[productId] as Map<String, dynamic>;
        final productRef = FirebaseFirestore.instance.collection('orders').doc(orderRef.id).collection('cart').doc(productId);
        await productRef.set({
          'product_image_url': productData['image_url'], // Include product image URL
          'product_name': productData['name'], // Include product image URL
          'price': productData['price'], // Include product image URL
          'quantity': quantity,
          // Add other relevant data
        });
      });

      // Prepare order data
      Map<String, dynamic> orderData = {
        'orderID': orderRef.id,

        'storeID': storeId,
        'email': prefs.getString('email'),
        'total': totalPrice.toString(),
        // Add other relevant data
      };

      final response = await http.post(
        Uri.parse('https://polskoydm.pythonanywhere.com/create-checkout-session'), // Parse the URL string to Uri
        body: json.encode(orderData),
        headers: {'Content-Type': 'application/json'},
      );


      if (response.statusCode == 200) {


        // Parse response JSON
        Map<String, dynamic> responseData = json.decode(response.body);
        String sessionUrl = responseData['sessionUrl'];

        // Open URL in default browser
        await launch(sessionUrl);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NavigationPage()),
        );
      } else {
        // Failed to submit order, handle error
        print('Failed to submit order: ${response.statusCode}');
        // Optionally, you can show an error message to the user
      }
      // Optionally, you can show a confirmation dialog or navigate to a new screen after submitting the order
    }
  }


  // Function to get latitude and longitude from address using Google Maps Geocoding API
  Future<Map<String, double>> getLatLngFromAddress(String address) async {
    final apiKey = 'AIzaSyA1Cn3fZigsdTv-4iBocFqo7cWk2Q5I1MA'; // Replace with your Google Maps API key
    final endpoint = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey');

    final response = await http.get(endpoint);
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final location = result['results'][0]['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];
      return {'latitude': lat, 'longitude': lng};
    } else {
      throw Exception('Failed to get coordinates from address');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _merchantAndProductFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  final merchantData =
                  snapshot.data!['merchantData'] as Map<String, dynamic>;
                  final merchantName = merchantData['name'];
                  final merchantAddress = merchantData['address'];

                  return FutureBuilder<Map<String, dynamic>>(
                    future: getLatLngFromAddress(merchantAddress),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      } else {
                        final coordinates = snapshot.data!;
                        final merchantLatitude = coordinates['latitude'];
                        final merchantLongitude = coordinates['longitude'];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restaurant: $merchantName',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              '$merchantAddress',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 16.0),
                            Container(
                              height: 200,
                              child: GoogleMap(
                                initialCameraPosition:
                                CameraPosition(
                                  target: LatLng(
                                      merchantLatitude, merchantLongitude),
                                  zoom: 15,
                                ),
                                markers: {
                                  Marker(
                                    markerId:
                                    MarkerId(merchantData['address']),
                                    position: LatLng(merchantLatitude,
                                        merchantLongitude),
                                    infoWindow: InfoWindow(
                                      title: merchantName,
                                      snippet: merchantAddress,
                                    ),
                                  ),
                                },
                                onMapCreated:
                                    (GoogleMapController controller) {},
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _merchantAndProductFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  final productsData =
                  snapshot.data!['productsData'] as Map<String, dynamic>;

                  final total = widget.cartItems.entries.fold<int>(
                      0,
                          (previousValue, entry) {
                        final productId = entry.key;
                        final quantity = entry.value;
                        final productData =
                        productsData[productId] as Map<String, dynamic>;
                        final price = (productData['price'] as double).toInt();
                        return previousValue + (price * quantity);
                      });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Image')),
                            DataColumn(label: Text('Product')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Quantity')),
                          ],
                          rows: widget.cartItems.entries.map((entry) {
                            final productId = entry.key;
                            final quantity = entry.value;

                            final productData =
                            productsData[productId] as Map<String, dynamic>;
                            final imageUrl =
                            productData['image_url'] as String;
                            final name = productData['name'] as String;
                            final price =
                            (productData['price'] as double).toInt();

                            return DataRow(
                              cells: [
                                DataCell(Image.network(imageUrl)),
                                DataCell(Text(name)),
                                DataCell(Text('\$$price')),
                                DataCell(Text(quantity.toString())),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      Divider(), // Divider after the DataTable
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Total: \$${total.toString()}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),

                        ),

                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0), // Adjust the value as needed
                        child: ElevatedButton(
                          onPressed: _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text('Payment', style: TextStyle(color: Colors.white)),
                        ),
                      ),

                    ],
                  );
                }
              },
            ),
          ),


        ],
      ),
    );
  }

}

