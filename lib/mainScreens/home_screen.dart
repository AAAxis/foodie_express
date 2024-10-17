import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orderapp/global/global.dart';
import 'package:orderapp/splashScreen/splash_screen.dart';
import 'menu_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _restaurantsStream;
  TextEditingController searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredRestaurants = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> allRestaurants = [];
  String? selectedFoodType; // Variable to hold selected food type
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _restaurantsStream = FirebaseFirestore.instance
        .collection('merchants')
        .where('receivingOrders', isEqualTo: true)
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (data, _) => data,
    )
        .snapshots();

    // Fetch all restaurants for initial filtering
    _restaurantsStream.listen((snapshot) {
      setState(() {
        allRestaurants = snapshot.docs; // Store all restaurants
        filteredRestaurants = allRestaurants; // Initialize filteredRestaurants
      });
    });

    restrictBlockedUsersFromUsingApp();
  }

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

  void searchRestaurants(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRestaurants = allRestaurants;
      } else {
        filteredRestaurants = allRestaurants.where((restaurant) =>
            restaurant.data()['name']
                .toLowerCase()
                .contains(query.toLowerCase())).toList();
      }
    });
  }

  void filterByFoodType(String foodType) {
    setState(() {
      selectedFoodType = foodType; // Update selected food type

      filteredRestaurants = allRestaurants.where((restaurant) {
        // Assuming you have a field 'foodType' in your restaurant data
        return restaurant.data()['type'] == foodType;
      }).toList();

      searchController.clear(); // Clear the search bar when filtering by food type
    });
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLargeScreen = constraints.maxWidth > 600;
          return isLargeScreen ? _buildTabletLayout() : _buildPhoneLayout();
        },
      ),
    );
  }

  // Phone Layout
  Widget _buildPhoneLayout() {
    return Column(
      children: [
        SizedBox(height: 20),
        _buildCarousel(height: 250.0),
        SizedBox(height: 20),
        _buildSearchBar(),
        SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: filteredRestaurants.length,
            itemBuilder: (context, index) {
              final restaurant = filteredRestaurants[index];
              final data = restaurant.data();
              final imageUrl = '${data['link']}';

              return GestureDetector(
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
                child: Card(
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
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        SizedBox(height: 20),
        _buildCarousel(height: 230.0),
        SizedBox(height: 20),
        _buildSearchBar(),
        SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              // Left Side: Filter Section
              Container(
                width: 200, // Adjust width as necessary
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Type',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Food Type Filter
                    _buildFoodTypeFilter(),
                  ],
                ),
              ),
              VerticalDivider(
                thickness: 1,
                color: Colors.grey,
              ),
              // Right Side: Restaurant List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = filteredRestaurants[index];
                    final data = restaurant.data();
                    final imageUrl = data['link'];

                    return GestureDetector(
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
                      child: Container(
                        margin: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15.0),
                                bottomLeft: Radius.circular(15.0),
                              ),
                              child: Image.network(
                                imageUrl,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(data['address']),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoodTypeFilter() {
    List<String> foodTypes = [
      'Hamburger',
      'Burrito',
      'Ramen',
      'Sushi',
      'Coffee',
    ];

    return Wrap(
      spacing: 8.0, // Space between bubbles
      runSpacing: 8.0, // Space between rows of bubbles
      children: List.generate(foodTypes.length, (index) {
        return ChoiceChip(
          label: Text(foodTypes[index]),
          selected: selectedFoodType == foodTypes[index],
          onSelected: (selected) {
            filterByFoodType(foodTypes[index]); // Pass the selected food type
          },
          selectedColor: Colors.blue,
          backgroundColor: Colors.grey.shade200,
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Search Restaurants',
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              searchController.clear();
              searchRestaurants(''); // Clear search
            },
          ),
        ),
        onChanged: (value) {
          searchRestaurants(value);
        },
      ),
    );
  }

  Widget _buildCarousel({required double height}) {
    return CarouselSlider(
      options: CarouselOptions(
        height: height,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 2.0,
      ),
      items: [
        'images/image1.png',
        'images/image2.png',
        'images/image3.png',
      ].map((item) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(item),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
