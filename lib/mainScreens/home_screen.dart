import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:order_app/global/global.dart';
import 'package:order_app/splashScreen/splash_screen.dart';
import 'menu_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _restaurantsStream;
  List<Map<String, dynamic>> filteredRestaurants = [];
  TextEditingController searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void restrictBlockedUsersFromUsingApp() async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseAuth.currentUser!.uid)
        .get()
        .then((snapshot) {
      if (snapshot.data()!["status"] != "approved") {
        firebaseAuth.signOut();
        Fluttertoast.showToast(msg: "You have been Blocked");
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => MySplashScreen()));
      } else {
        Fluttertoast.showToast(msg: "Login Successful");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _restaurantsStream = FirebaseFirestore.instance.collection('merchants').where('receivingOrders', isEqualTo: true).snapshots();
    restrictBlockedUsersFromUsingApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Restaurants",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.restaurant_outlined),
          onPressed: () {},
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          CarouselSlider(
            options: CarouselOptions(
              height: 250.0,
              enableInfiniteScroll: true,
              autoPlay: true,
            ),
            items: [
              AssetImage('images/image1.png'),
              AssetImage('images/image2.png'),
              AssetImage('images/image3.png'),
            ].map((image) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                    ),
                    child: Image(
                      image: image,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Text(
            "Picked for You",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _restaurantsStream,
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                final restaurants = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    final data = restaurant.data() as Map<String, dynamic>;
                    final imageUrl = '${data['link']}';

                    return Card(
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name']),
                            Text(data['address']),
                          ],
                        ),
                        leading: Image.network(
                          imageUrl,
                          width: 80.0,
                          height: 80.0,
                          fit: BoxFit.cover,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuPage(
                                storeId: restaurant.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
