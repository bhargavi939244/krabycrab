import 'package:flutter/material.dart';
import 'firestore_service.dart'; // Import the single source of truth for PaymentMethod

// The enum PaymentMethod is now defined in firestore_service.dart, so we no longer need it here.

// PaymentWidget is a StatefulWidget to manage the selected payment option.
class PaymentWidget extends StatefulWidget {
  // Correct the type to explicitly expect a function that returns void.
  final void Function(PaymentMethod) onPaymentMethodSelected;

  const PaymentWidget({Key? key, required this.onPaymentMethodSelected}) : super(key: key);

  @override
  _PaymentWidgetState createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends State<PaymentWidget> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cod;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          // Card for Cash on Delivery (COD)
          Card(
            elevation: _selectedPaymentMethod == PaymentMethod.cod ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedPaymentMethod == PaymentMethod.cod
                    ? Colors.red
                    : Colors.grey.shade300,
                width: _selectedPaymentMethod == PaymentMethod.cod ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = PaymentMethod.cod;
                });
                widget.onPaymentMethodSelected(_selectedPaymentMethod);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Radio<PaymentMethod>(
                      value: PaymentMethod.cod,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (PaymentMethod? value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                        widget.onPaymentMethodSelected(_selectedPaymentMethod);
                      },
                      activeColor: Colors.red,
                    ),
                    const Icon(Icons.money, color: Colors.green, size: 28),
                    const SizedBox(width: 16),
                    const Text(
                      'Cash on Delivery',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Card for Credit/Debit Card
          Card(
            elevation: _selectedPaymentMethod == PaymentMethod.card ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedPaymentMethod == PaymentMethod.card
                    ? Colors.red
                    : Colors.grey.shade300,
                width: _selectedPaymentMethod == PaymentMethod.card ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = PaymentMethod.card;
                });
                widget.onPaymentMethodSelected(_selectedPaymentMethod);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Radio<PaymentMethod>(
                      value: PaymentMethod.card,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (PaymentMethod? value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                        widget.onPaymentMethodSelected(_selectedPaymentMethod);
                      },
                      activeColor: Colors.red,
                    ),
                    const Icon(Icons.credit_card, color: Colors.blue, size: 28),
                    const SizedBox(width: 16),
                    const Text(
                      'Credit / Debit Card',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
