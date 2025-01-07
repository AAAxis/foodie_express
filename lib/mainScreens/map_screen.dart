import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orderapp/mainScreens/success_screen.dart';
import '../global/global.dart';



class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(0, 0); // Center of the world coordinates
  String? userAddress;
  String? destinationAddress;
  Position? _userPosition; // User's current position
  double distanceInMeters = 0.0; // To store the calculated distance
  String? selectedCarType = 'Regular'; // Variable to store the selected car type
  String? selectedPaymentMethod = 'Cash'; // Set the default value to 'Cash'

  // Method to set the selected car type
  void setSelectedCarType(String type) {
    setState(() {
      selectedCarType = type;
    });
  }

  // Method to set the destination address
  void setDestinationAddress(String address) {
    setState(() {
      destinationAddress = address;
    });
  }

  Future<void> calculateDistance() async {
    if (_userPosition != null &&
        destinationAddress != null &&
        destinationAddress!.isNotEmpty) {
      double userLatitude = _userPosition!.latitude;
      double userLongitude = _userPosition!.longitude;
      double destinationLatitude = 0.0;
      double destinationLongitude = 0.0;

      final apiKey = 'AIzaSyA1Cn3fZigsdTv-4iBocFqo7cWk2Q5I1MA';

      final address = Uri.encodeFull(destinationAddress!);
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'] is List) {
            final location = data['results'][0]['geometry']['location'];
            destinationLatitude = location['lat'];
            destinationLongitude = location['lng'];

            // Calculate the distance
            double calculatedDistance = Geolocator.distanceBetween(
              userLatitude,
              userLongitude,
              destinationLatitude,
              destinationLongitude,
            );

            setState(() {
              distanceInMeters = calculatedDistance;
            });



            print("Distance: ${distanceInMeters.toStringAsFixed(2)} meters");
          } else {
            print("Error fetching destination coordinates.");
          }
        } else {
          print("Error fetching destination coordinates.");
        }
      } catch (e) {
        print("Error fetching destination coordinates: $e");
      }
    } else {
      print(
          "Cannot calculate distance and price. Please make sure both addresses are available.");
    }
  }

  Future<void> _requestLocation() async {
    // Request location permission
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      return; // Handle the case where the user denied location permission
    }

    // Fetch user's location
    Position position = await Geolocator.getCurrentPosition();

    // Update user's position
    setState(() {
      _userPosition = position;
    });

    // Fetch address based on coordinates
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark placemark = placemarks[0];
        final address =
            "${placemark.street}, ${placemark.locality}, ${placemark.country}";

        setState(() {
          userAddress = address;
        });

        // Save the user's address to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userAddress', address);
      }
    } catch (e) {
      print("Error fetching address: $e");
    }

    // Update the camera to focus on the user's location
    if (_userPosition != null) {
      CameraPosition newCameraPosition = CameraPosition(
        target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        zoom: 15.0, // You can adjust the zoom level as per your preference
      );
      mapController.animateCamera(
          CameraUpdate.newCameraPosition(newCameraPosition));
    }
  }



  int getCarPrice(String carType) {
    if (carType == 'Regular') {
      int price = (distanceInMeters / 1000 * 2.0).toInt();
      return price < 100 ? 100 : price;
    } else if (carType == 'Bike') {
      double price = distanceInMeters / 1000 * 2.0 - 100;
      return (price < 50 ? 50 : price).toInt();
    }
    return 0; // Default to 0 if carType is not recognized
  }


  Future<void> createOrder() async {
    final apiUrl = 'https://polskoydm.pythonanywhere.com/taxi_order'; // Replace with your API endpoint

    // Calculate the order details
    double distanceInKilometers = distanceInMeters / 1000;
    const double pricePerKilometer = 2.0;
    double price = distanceInKilometers * pricePerKilometer;

    // Adjust the price based on the selected car type
    if (selectedCarType == 'Bike') {
      price = (price - 100 < 100) ? 100 : price - 100;
    }

    String formattedPrice = price.toStringAsFixed(1);
    int roundedDistanceInKilometers = distanceInKilometers.round();
    String formattedDistanceInKilometers = roundedDistanceInKilometers.toString();

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json', // Set the content type to JSON
      },
      body: json.encode({
        'name':     sharedPreferences!.getString("name") ?? "No Name",
        'email':     sharedPreferences!.getString("email") ?? "No Email",
        'total': formattedPrice,
        'distance': formattedDistanceInKilometers,
        'start_point': userAddress,
        'address': destinationAddress,
      }),
    );

    if (response.statusCode == 200) {
      // Successfully sent the request
      print('API Request Success: ${response.body}');

      final responseJson = json.decode(response.body);
      final orderID = responseJson['order_id'].toString(); // Convert to String

// Now, you have the order ID and can proceed to the payment link
      if (orderID != null) {
        if (selectedPaymentMethod == 'Cash') {
          // Display instructions or navigate to a page for cash payment
          navigateToCashPayment(orderID);
        }
      } else {
        print('Order ID not found in response.');
        // Handle the scenario where order ID is not available.
      }

    } else {
      // Handle API request failure
      print('API Request Failed: ${response.statusCode} - ${response.reasonPhrase}');
      // Handle the failure as needed
    }
  }


  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }




  Future<void> navigateToCashPayment(String orderID) async {


    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SuccessPage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: _userPosition != null
                ? CameraPosition(
              target: LatLng(
                  _userPosition!.latitude, _userPosition!.longitude),
              zoom: 15.0,
            )
                : CameraPosition(
              target: _center,
              zoom: 1.0,
            ),
            markers: _userPosition != null
                ? Set<Marker>.from([
              Marker(
                markerId: MarkerId("user_location"),
                position: LatLng(
                    _userPosition!.latitude, _userPosition!.longitude),
                icon: BitmapDescriptor.defaultMarker,
              ),
            ])
                : Set<Marker>(),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: userAddress ?? "My Location",
                            ),
                            onChanged: (value) {
                              setState(() {
                                userAddress = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Start Location",
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.location_on),
                          onPressed: () async {
                            await _requestLocation();
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            onChanged: (value) {
                              setDestinationAddress(value);
                              calculateDistance();
                            },
                            decoration: InputDecoration(
                              labelText: "End Location",
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_box_outlined),
                          onPressed: () async {
                            calculateDistance();
                          },
                        ),
                      ],
                    ),
                  ),
                  // Add car type selection icons
                  // Inside the car type selection section
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Regular Car
                        Card(
                          elevation: 5,
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(5.0),
                                child: IconButton(
                                  icon: Icon(Icons.directions_car, size: 30.0),
                                  onPressed: () {
                                    setSelectedCarType('Regular');
                                  },
                                  color: selectedCarType == 'Regular'
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              Text('Regular'),
                              Text('\$${getCarPrice('Regular')}'),
                            ],
                          ),
                        ),


                        // Bike
                        Card(
                          elevation: 5,
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(5.0),
                                child: IconButton(
                                  icon: Icon(Icons.motorcycle, size: 30.0),
                                  onPressed: () {
                                    setSelectedCarType('Bike');
                                  },
                                  color: selectedCarType == 'Bike'
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              Text('Bike'),
                              Text('\$${getCarPrice('Bike')}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.money,
                                color: Colors.green,
                                size: 30.0,
                              ),
                              SizedBox(width: 10.0),
                              DropdownButton<String>(
                                value: selectedPaymentMethod,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedPaymentMethod = newValue;
                                  });
                                },
                                items: <String>['Cash']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              // Check if all required parameters are available before creating the order
                              if (distanceInMeters > 0 &&
                                  destinationAddress != null &&
                                  destinationAddress!.isNotEmpty &&
                                  selectedPaymentMethod != null &&
                                  selectedPaymentMethod!.isNotEmpty) {
                                // Check if email, phone, and name are available and not empty in SharedPreferences
                                final email = sharedPreferences!.getString("email");
                                final phone = sharedPreferences!.getString("phone");
                                final name = sharedPreferences!.getString("name");
                                if (email != null && email.isNotEmpty &&
                                    phone != null && phone.isNotEmpty &&
                                    name != null && name.isNotEmpty) {
                                  createOrder();
                                } else {
                                  // Show an error message or handle the case where email, phone, or name is not available or empty
                                  showErrorDialog(context, "Please provide your email, phone, and name in the settings.");
                                }
                              } else {
                                // Show an error message or handle the case where not all parameters are available
                                showErrorDialog(context, "Please provide all required information.");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(120, 50),
                            ),
                            child: Text(
                              'Request',
                              style: TextStyle(fontSize: 20, color: Colors.black),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
