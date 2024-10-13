import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orderapp/mainScreens/cart_page.dart';

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
    if (_cartItems.values.any((quantity) => quantity > 0)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartPage(storeId: widget.storeId, cartItems: _cartItems),
        ),
      );
    } else {
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
                            height: 170,
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
                            top: 5,
                            right: 5,
                            child: Container(
                              padding: EdgeInsets.all(5),
                              color: Colors.black.withOpacity(0.7),
                              child: Text(
                                '${product['name']} x ${getQuantity(productId)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5, // Adjust left position if needed
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    removeFromCart(productId);
                                  },
                                  child: Icon(Icons.remove, color: Colors.white),
                                  style: ElevatedButton.styleFrom(
                                    shape: CircleBorder(),
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.all(8),
                                  ),
                                ),
                                SizedBox(height: 2),
                                ElevatedButton(
                                  onPressed: () {
                                    addToCart(productId);
                                  },
                                  child: Icon(Icons.add, color: Colors.white),
                                  style: ElevatedButton.styleFrom(
                                    shape: CircleBorder(),
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.all(8),
                                  ),
                                ),// Space between the buttons

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
