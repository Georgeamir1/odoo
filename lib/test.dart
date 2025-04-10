import 'package:flutter/material.dart';
import 'package:bluetooth_print_all_platform/bluetooth_print_all_platform.dart';

class FunctionPage extends StatefulWidget {
  final BluetoothDevice device;

  const FunctionPage({Key? key, required this.device}) : super(key: key);

  @override
  State<FunctionPage> createState() => _FunctionPageState();
}

class _FunctionPageState extends State<FunctionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connected: ${widget.device.name}'),
      ),
      body: Center(
        child: Text(
          'Implement your printing functions here for device: ${widget.device.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
