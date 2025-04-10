import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'localization.dart';

class InVoicePrintScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const InVoicePrintScreen({super.key, required this.orderData});

  @override
  State<InVoicePrintScreen> createState() => _InVoicePrintScreenState();
}

class _InVoicePrintScreenState extends State<InVoicePrintScreen> {
  bool connected = false;
  List<BluetoothInfo> availableBluetoothDevices = [];
  bool _isLoading = false;
  final List<int> _paperSizeList = [80, 58];
  int _selectedSize = 80;
  ScreenshotController screenshotController = ScreenshotController();
  String? _warningMessage;
  String selectedMacAddress = '';

  Map<String, dynamic> _hardcodedOrder = {};

  @override
  void initState() {
    super.initState();
    _hardcodedOrder = {
      'customer_name': widget.orderData['customer_name'],
      'user_name': widget.orderData['user_name'],
      'total': widget.orderData['total_with_vat'],
      'items': widget.orderData['items'],
      'amount_untaxed': widget.orderData['total_before_vat'],
      'tax': widget.orderData['vat_amount'],
    };

    _loadBluetoothDevices();
  }

  Future<void> _loadBluetoothDevices() async {
    setState(() => _isLoading = true);

    try {
      availableBluetoothDevices = await PrintBluetoothThermal.pairedBluetooths;
      connected = await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      _warningMessage = "Failed to load Bluetooth devices";
    }

    setState(() => _isLoading = false);
  }

  Future<void> _connectToPrinter(String mac) async {
    setState(() => _isLoading = true);

    try {
      final success =
          await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      setState(() {
        connected = success;
        if (success) selectedMacAddress = mac;
      });
    } catch (e) {
      _warningMessage = "Failed to connect to printer";
    }

    setState(() => _isLoading = false);
  }

  Future<void> _printReceipt() async {
    if (!connected) {
      _showMessage("No printer connected");
      return;
    }

    try {
      final Uint8List? image = await screenshotController.capture();
      if (image == null) {
        _showMessage("Failed to capture invoice");
        return;
      }

      final ticket = await _prepareTicket(image);
      await PrintBluetoothThermal.writeBytes(ticket);
      _showMessage("Printing started");
      Navigator.of(context).pop(); // Close dialog after printing starts
    } catch (e) {
      _showMessage("Printing failed: ${e.toString()}");
    }
  }

  Future<List<int>> _prepareTicket(Uint8List image) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        _selectedSize == 80 ? PaperSize.mm80 : PaperSize.mm58, profile);

    final decodedImage = img.decodeImage(image);
    if (decodedImage == null) {
      throw Exception("Failed to decode image");
    }

    final resizedImage =
        _resizeImage(decodedImage, _selectedSize == 80 ? 500 : 365);

    List<int> bytes = [];
    bytes += generator.image(resizedImage);
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  img.Image _resizeImage(img.Image image, int width) {
    return img.copyResize(
      image,
      width: width,
      height: (image.height * (width / image.width)).toInt(),
      interpolation: img.Interpolation.average,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Print Invoice",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),

          // Printer selection section
          _buildPrinterSelection(),
          SizedBox(
            height: 8,
          ),
          // Invoice preview section
          Expanded(
            child: SingleChildScrollView(
              child: Screenshot(
                controller: screenshotController,
                child: _buildInvoicePreview(),
              ),
            ),
          ),

          // Print button
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _printReceipt,
                child: const Text("PRINT INVOICE"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SELECT PRINTER",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Paper Size:"),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedSize,
                  items: _paperSizeList.map((size) {
                    return DropdownMenuItem<int>(
                      value: size,
                      child: Text("$size mm"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedSize = value!),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadBluetoothDevices,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (availableBluetoothDevices.isEmpty)
              Text(_warningMessage ?? "No printers found",
                  style: TextStyle(color: Colors.red))
            else
              ...availableBluetoothDevices.map((device) => ListTile(
                    title: Text(device.name),
                    subtitle: Text(device.macAdress),
                    trailing: device.macAdress == selectedMacAddress
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => _connectToPrinter(device.macAdress),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(widget.orderData['company_name'],
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('______________________________________'),
                ],
              ),
            ),
            // Customer info
            Text(
                "${AppLocalizations.of(context).customer}: ${_hardcodedOrder['customer_name']}"),
            Text(
                "${AppLocalizations.of(context).sales}: ${_hardcodedOrder['user_name']}"),
            const SizedBox(height: 16),

            // Order items
            Text(AppLocalizations.of(context).items,
                style: TextStyle(fontWeight: FontWeight.bold)),
            ..._hardcodedOrder['items'].map<Widget>((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${item['quantity']}"),
                      Text("X   ${item['name']}"),
                      Text("\$${item['price'].toStringAsFixed(2)}"),
                    ],
                  ),
                )),

            // Totals

            Text('______________________________________'),
            _buildTotalRow(
                "${AppLocalizations.of(context).tax}", _hardcodedOrder['tax']),
            _buildTotalRow("${AppLocalizations.of(context).total}",
                _hardcodedOrder['total'],
                isTotal: true),

            // Footer
            const SizedBox(height: 16),
            const Center(child: Text("Thank you for your order!")),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label,
              style: isTotal ? TextStyle(fontWeight: FontWeight.bold) : null),
          const Spacer(),
          Text("${amount.toStringAsFixed(2)}",
              style: isTotal ? TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }
}
