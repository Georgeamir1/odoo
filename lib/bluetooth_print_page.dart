/*
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
// Removed unused import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

class BluetoothPrintPage extends StatefulWidget {
  const BluetoothPrintPage({super.key});

  @override
  State<BluetoothPrintPage> createState() => _BluetoothPrintPageState();
}

class _BluetoothPrintPageState extends State<BluetoothPrintPage> {
  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

  List<Printer> printers = [];
  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  // Start scanning for Bluetooth printers
  void startScan() async {
    _devicesStreamSubscription?.cancel();
    await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
      ConnectionType.BLE,
    ]);
    _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream
        .listen((List<Printer> event) {
      log(event.map((e) => e.name).toList().toString());
      setState(() {
        printers = event;
        printers.removeWhere(
            (element) => element.name == null || element.name == '');
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      startScan();
    });
  }

  void connect(Printer printer) async {
    await _flutterThermalPrinterPlugin.connect(printer);
  }

  void stopScan() {
    _flutterThermalPrinterPlugin.stopScan();
  }

  @override
  void dispose() {
    _devicesStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Print Page'),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bluetooth Printers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      startScan();
                    },
                    child: const Text('Scan Printers'),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      stopScan();
                    },
                    child: const Text('Stop Scan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: printers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () async {
                      if (printers[index].isConnected ?? false) {
                        await _flutterThermalPrinterPlugin
                            .disconnect(printers[index]);
                      } else {
                        await _flutterThermalPrinterPlugin
                            .connect(printers[index]);
                      }
                    },
                    title: Text(printers[index].name ?? 'No Name'),
                    subtitle: Text("Connected: ${printers[index].isConnected}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () async {
                        connect(printers[index]);
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                */
/* if (printers.isNotEmpty) {
                  _flutterThermalPrinterPlugin.printData(
                    Printer(
                      name: printers[0].name,
                      address: printers[0].address,
                      connectionType: printers[0].connectionType,
                      isConnected: printers[0].isConnected,
                    ),
                    utf8.encode("Sample print data"),
                    longData: true,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No printer found'),
                    ),
                  );
                }*/ /*

              },
              child: const Text('Scan Printers'),
            ),
          ],
        ),
      ),
    );
  }

  Widget receiptWidget(String printerType) {
    return SizedBox(
      width: 550,
      child: Material(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'FLUTTER THERMAL PRINTER',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 10),
              _buildReceiptRow('Item', 'Price'),
              const Divider(),
              _buildReceiptRow('Apple', '\$1.00'),
              _buildReceiptRow('Banana', '\$0.50'),
              _buildReceiptRow('Orange', '\$0.75'),
              const Divider(thickness: 2),
              _buildReceiptRow('Total', '\$2.25', isBold: true),
              const SizedBox(height: 20),
              _buildReceiptRow('Printer Type', printerType),
              const SizedBox(height: 50),
              const Center(
                child: Text(
                  'Thank you for your purchase!',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildReceiptRow(String leftText, String rightText,
    {bool isBold = false}) {
  return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            leftText,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            rightText,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ));
}
*/
