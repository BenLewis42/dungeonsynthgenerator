import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firestore_service.dart';
import 'payment_screen.dart';
import 'return_album_screen.dart';

class MyMusicScreen extends StatefulWidget {
  @override
  _MyMusicScreenState createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  bool _hasOrdered = false;
  bool _orderSent = false;
  bool _returnConfirmed = false;
  DocumentSnapshot? _order;

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus();
  }

  Future<void> _fetchOrderStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .get();
        if (orderSnapshot.docs.isNotEmpty) {
          final order = orderSnapshot.docs.first;
          final orderData = order.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _hasOrdered = true;
              _order = order;
              _orderSent = orderData['status'] == 'sent';
              _returnConfirmed = orderData['returnConfirmed'] ?? false;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Music'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final orderData = _order?.data() as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Music'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _hasOrdered
            ? (orderData != null && orderData.containsKey('status'))
                ? orderData['status'] == 'sent'
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Your album is on its way!',
                              style: TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.0),
                            SpoilerWidget(order: _order!),
                          ],
                        ),
                      )
                    : orderData['status'] == 'new'
                        ? Center(
                            child: Text(
                              'We\'ll let you know once your album has been sent!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : orderData['status'] == 'returnedConfirmed'
                            ? Center(
                                child: Text(
                                  'Order an album to see your music show up here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              )
                            : Center(
                                child: Text(
                                  'More information will be available here once your album is shipped.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              )
                : Center(
                    child: Text(
                      'Order an album to see your music show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  )
            : Center(
                child: Text(
                  'Order an album to see your music show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
      ),
    );
  }
}

class SpoilerWidget extends StatefulWidget {
  final DocumentSnapshot order;

  SpoilerWidget({required this.order});

  @override
  _SpoilerWidgetState createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<SpoilerWidget> {
  bool _isSpoilerOpen = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final orderDetails = widget.order.data() as Map<String, dynamic>?;

    if (orderDetails == null || !orderDetails.containsKey('details') || !orderDetails['details'].containsKey('albumId')) {
      return Text('Error loading order details.');
    }

    final albumId = orderDetails['details']['albumId'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isSpoilerOpen = !_isSpoilerOpen;
            });
          },
          child: Text(_isSpoilerOpen ? 'Hide Album' : 'View Album'),
        ),
        if (_isSpoilerOpen) ...[
          SizedBox(height: 16.0),
          FutureBuilder<DocumentSnapshot>(
            future: _firestoreService.getAlbumById(albumId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData) {
                final album = snapshot.data!.data() as Map<String, dynamic>;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (album['coverUrl'] != null) 
                      Image.network(album['coverUrl'], height: 150, width: 150),
                    Text('Artist: ${album['artist']}', style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
                    Text('Album: ${album['albumName']}', style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ReturnAlbumScreen(orderId: widget.order.id)),
                        ).then((value) {
                          if (value == true) {
                            setState(() {
                              _isSpoilerOpen = false;
                            });
                          }
                        });
                      },
                      child: Text('Return Your Album'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PaymentScreen(orderId: widget.order.id)),
                        );
                        if (result == true) {
                          setState(() {
                            _isSpoilerOpen = false;
                          });
                        }
                      },
                      child: Text('Keep Your Album'),
                    ),
                  ],
                );
              } else {
                return Text('Error loading album details');
              }
            },
          ),
        ]
      ],
    );
  }
}