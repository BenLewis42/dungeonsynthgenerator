import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '/services/firestore_service.dart';
import '/services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;

  PaymentScreen({required this.orderId});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  String? _errorMessage; // Change to nullable String

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Create PaymentIntent on the server
      final paymentIntentData = await _paymentService.createPaymentIntent(899);

      // 2. Initialize the payment sheet
      await _paymentService.initPaymentSheet(paymentIntentData['clientSecret']);

      // 3. Display the payment sheet
      await _paymentService.presentPaymentSheet();

      // 4. Handle payment success
      await _firestoreService.updateOrderStatus(widget.orderId, 'kept');

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful. Enjoy your new album!')),
      );

      Navigator.pop(context, true);
    } on StripeException catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment canceled.')),
        );
        Navigator.pop(context, false);
      } else {
        setState(() {
          _errorMessage = e.error.localizedMessage ?? 'Payment failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${_errorMessage}')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $_errorMessage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keep Your Album'),
      ),
      body: _isProcessing
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\$8.99',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _processPayment,
                    child: Text('Purchase'),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}