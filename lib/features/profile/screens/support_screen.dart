import 'package:flutter/material.dart';
import '../../home/screens/customer_support_screen.dart';

class SupportScreen extends StatelessWidget {
  static const String routeName = 'support';

  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Destek'),
        centerTitle: true,
      ),
      body: const CustomerSupportScreen(hideTitle: true),
    );
  }
}
