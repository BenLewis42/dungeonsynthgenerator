import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ReturnAlbumScreen extends StatefulWidget {
  final String orderId;

  ReturnAlbumScreen({required this.orderId});

  @override
  _ReturnAlbumScreenState createState() => _ReturnAlbumScreenState();
}

class _ReturnAlbumScreenState extends State<ReturnAlbumScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String _heardBefore = 'Yes';
  String _ownAlbum = 'Yes';
  String _likedAlbum = 'Yes!';
  String _miscThoughts = '';

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Collect the feedback data
      Map<String, dynamic> feedback = {
        'heardBefore': _heardBefore,
        'ownAlbum': _ownAlbum,
        'likedAlbum': _likedAlbum,
        'miscThoughts': _miscThoughts,
      };

      // Save the feedback to Firestore
      await _firestoreService.submitFeedback(widget.orderId, feedback);

      // Update the order status to 'returned'
      await _firestoreService.updateOrderStatus(widget.orderId, 'returned');

      setState(() {
        _isSubmitting = false;
      });

      // Navigate back to MyMusicScreen
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Return Album'),
      ),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      'Please provide your feedback on the album:',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Had you heard this album before?'),
                      value: _heardBefore,
                      items: ['Yes', 'No'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _heardBefore = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Do you already own this album?'),
                      value: _ownAlbum,
                      items: ['Yes', 'No'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _ownAlbum = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Did you like this album?'),
                      value: _likedAlbum,
                      items: ['Yes!', 'Meh', 'Nah'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _likedAlbum = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Any other thoughts?'),
                      maxLines: 3,
                      onChanged: (value) {
                        setState(() {
                          _miscThoughts = value;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Submit Feedback'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}