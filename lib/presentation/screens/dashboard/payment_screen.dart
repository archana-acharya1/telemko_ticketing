import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  return Scaffold(
    appBar: AppBar(
      title: Text(
        "Make Payment",
        style: theme.textTheme.titleLarge,
      ),
      centerTitle: true,
    ),

    body: Center(
      child: Text(
        "Payment Page",
        style: theme.textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    ),
  );
}
}