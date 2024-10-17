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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if the screen width is large enough to show 2 columns
            bool isTablet = constraints.maxWidth > 600; // Adjust this width based on your preference

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('merchants')
                  .doc(widget.storeId)
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No products available.'));
                } else {
                  final products = snapshot.data!.docs;

                  if (isTablet) {
                    // GridView for tablets (2 columns)
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Two columns on tablets
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3, // Adjust to fit the design
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index].data() as Map<String, dynamic>;
                        final productId = products[index].id;

                        return productCard(product, productId);
                      },
                    );
                  } else {
                    // ListView for phones (1 column)
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index].data() as Map<String, dynamic>;
                        final productId = products[index].id;

                        return productCard(product, productId);
                      },
                    );
                  }
                }
              },
            );
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

  // Helper method to create the product card
  Widget productCard(Map<String, dynamic> product, String productId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image on the left
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                image: DecorationImage(
                  image: NetworkImage(product['image_url']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 10),
            // Product Info and buttons on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$${product['price'].toString()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                      SizedBox(width: 10),
                      Text(
                        getQuantity(productId).toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(width: 10),
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
