import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:order_app/mainScreens/cart_page.dart';

class MenuPage extends StatefulWidget {
  final String storeId;

  MenuPage({required this.storeId});

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final Map<String, int> _cartItems = {};

  void addToCart(String productId) {
    setState(() {
      if (_cartItems.containsKey(productId)) {
        _cartItems[productId] = _cartItems[productId]! + 1;
      } else {
        _cartItems[productId] = 1;
      }
    });
  }

  void removeFromCart(String productId) {
    setState(() {
      if (_cartItems.containsKey(productId) && _cartItems[productId]! > 0) {
        _cartItems[productId] = _cartItems[productId]! - 1;
      }
    });
  }

  int getQuantity(String productId) {
    return _cartItems.containsKey(productId) ? _cartItems[productId]! : 0;
  }

  void navigateToCartPage() {
    // Check if any item is selected
    if (_cartItems.values.any((quantity) => quantity > 0)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartPage(storeId: widget.storeId, cartItems: _cartItems),
        ),
      );
    } else {
      // Display snack bar if no items are selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select items before proceeding to the cart.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('merchants').doc(widget.storeId).collection('products').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No products available.'));
            } else {
              final products = snapshot.data!.docs;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index].data() as Map<String, dynamic>;
                  final productId = products[index].id;
                  return GestureDetector(
                    onTap: () {
                      addToCart(productId);
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.vertical(top: Radius.circular(10.0)),
                              image: DecorationImage(
                                image: NetworkImage(
                                  '${product['image_url']}',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            left: 5,
                            child: Container(
                              padding: EdgeInsets.all(5),
                              color: Colors.white.withOpacity(0.7),
                              child: Text(
                                product['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 35,
                            right: 5,
                            child: Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    removeFromCart(productId);
                                  },
                                  child: Icon(Icons.remove, color: Colors.white),
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all(CircleBorder()),
                                    padding: MaterialStateProperty.all(EdgeInsets.all(8)),
                                    foregroundColor: MaterialStateProperty.all(Colors.white),
                                  ),
                                ),
                                Text(
                                  '${getQuantity(productId)}',
                                  style: TextStyle(fontSize: 18, color: Colors.white), // Set text color to white
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    addToCart(productId);
                                  },
                                  child: Icon(Icons.add, color: Colors.white),
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all(CircleBorder()),
                                    padding: MaterialStateProperty.all(EdgeInsets.all(8)),
                                    foregroundColor: MaterialStateProperty.all(Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          navigateToCartPage();
        },
        child: Icon(Icons.shopping_cart),
      ),
    );
  }
}
