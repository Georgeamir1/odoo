/*
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';

class BluetoothPrinterPage extends StatefulWidget {
  @override
  _BluetoothPrinterPageState createState() => _BluetoothPrinterPageState();
}

class _BluetoothPrinterPageState extends State<BluetoothPrinterPage> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedPrinter;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _scanForPrinters();
  }

  Future<void> _scanForPrinters() async {
    setState(() => _scanning = true);
    List<BluetoothDevice> devices = [];

    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print("Error scanning: $e");
    }

    setState(() {
      _devices = devices;
      _scanning = false;
    });
  }

  Future<void> _printTest() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a printer first!")),
      );
      return;
    }

    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm58, profile);

    try {
      final isConnected = await printer.connect(_selectedPrinter!.address, port: 9100);

      if (isConnected == PosPrintResult.success) {
        printer.text("Hello, this is a test print!", styles: PosStyles(align: PosAlign.center));
        printer.cut();
        printer.disconnect();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Print successful!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Print failed!")));
      }
    } catch (e) {
      print("Print error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bluetooth Printer")),
      body: Column(
        children: [
          _scanning
              ? CircularProgressIndicator()
              : _devices.isEmpty
              ? Text("No Bluetooth printers found!")
              : DropdownButton<BluetoothDevice>(
            value: _selectedPrinter,
            hint: Text("Select a printer"),
            isExpanded: true,
            items: _devices.map((device) {
              return DropdownMenuItem(
                value: device,
                child: Text(device.name ?? "Unknown"),
              );
            }).toList(),
            onChanged: (device) {
              setState(() => _selectedPrinter = device);
            },
          ),
          ElevatedButton(
            onPressed: _scanForPrinters,
            child: Text("Scan Again"),
          ),
          ElevatedButton(
            onPressed: _printTest,
            child: Text("Print Test"),
          ),
        ],
      ),
    );
  }
}
*/
