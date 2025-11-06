import 'package:flutter/material.dart';

class AddEditLiabilityPage extends StatelessWidget {
  const AddEditLiabilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Liability'),
      ),
      body: const Center(
        child: Text('Add/Edit Liability Form'),
      ),
    );
  }
}
