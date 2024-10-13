import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orderapp/widgets/navigation_bar.dart';
import '../global/global.dart';
import 'chat_room.dart';


class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  String userEmail = ''; // Store the user's UID
  List<Map<String, dynamic>> orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserUid(); // Call method to get user's UID
  }

  void getUserUid() async {
    // Get the current user's UID
    String user = sharedPreferences!.getString("email") ?? "No Email";
    if (user != null) {
      setState(() {
        userEmail = user;
      });
      fetchOrders(); // Call method to fetch orders after getting UID
    }
  }

  void fetchOrders() async {
    try {
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('email', isEqualTo: userEmail)
          .where('status', whereIn: ['paid', 'completed', 'assigned', 'picked up'])  // Add this line for filtering
          .get();

      setState(() {
        _isLoading = false;
        // Convert each document snapshot to a map and add to orders list
        orders = ordersSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          // Include the document ID in the order map
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        leading: IconButton(
          icon: Icon(Icons.history),
          onPressed: () {

          },
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : orders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No orders assigned.',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.only(top: 16.0), // Add padding to the top
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height,
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> order = orders[index];
                    String orderId = order['id']; // Retrieve the document ID

                    return Card(
                      elevation: 2.0,
                      child: ListTile(
                        leading: CircleAvatar(
                          // You can customize the avatar as per your design
                          child: Icon(Icons.person),
                          backgroundColor: Colors.black26, // Example color
                        ),
                        title: Text(order['name']),
                        subtitle: Text(orderId),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                height: MediaQuery.of(context).size.height * 0.8,
                                child: ChatRoomScreen(
                                  chatRoom: order,
                                  orderId: orderId, // Pass the document ID to ChatRoomScreen
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}