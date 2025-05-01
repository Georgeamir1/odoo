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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.indigo.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 24),
            _buildPrinterSection(),
            const SizedBox(height: 16),
            _buildInvoicePreviewSection(),
            const SizedBox(height: 16),
            _buildPrintButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Print Invoice",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: Colors.grey.shade600),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildPrinterSection() {
    return Container(
      height: 270,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.print, color: Colors.indigo.shade800),
                    const SizedBox(width: 8),
                    Text("Printer Settings",
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    _buildConnectionStatus(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPaperSizeSelector(),
                const SizedBox(height: 16),
                _buildPrinterList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Row(
      children: [
        Icon(
          Icons.circle,
          color: connected ? Colors.green.shade600 : Colors.red.shade600,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          connected ? "Connected" : "Disconnected",
          style: TextStyle(
            fontSize: 8,
            color: connected ? Colors.green.shade800 : Colors.red.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaperSizeSelector() {
    return Row(
      children: [
        Text("Paper Width:", style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: _selectedSize,
          items: _paperSizeList.map((size) {
            return DropdownMenuItem<int>(
              value: size,
              child: Text("$size mm", style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedSize = value!),
          underline: Container(height: 1, color: Colors.indigo.shade100),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.indigo.shade800),
          onPressed: _loadBluetoothDevices,
          tooltip: "Refresh printers",
        ),
      ],
    );
  }

  Widget _buildPrinterList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableBluetoothDevices.isEmpty) {
      return ListTile(
        leading: Icon(Icons.warning, color: Colors.orange.shade800),
        title: Text(_warningMessage ?? "No printers found"),
      );
    }

    return Column(
      children: availableBluetoothDevices
          .map((device) => _buildPrinterItem(device))
          .toList(),
    );
  }

  Widget _buildPrinterItem(BluetoothInfo device) {
    final isConnected = connected && device.macAdress == selectedMacAddress;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(Icons.bluetooth, color: Colors.blue.shade800),
      title: Text(device.name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle:
          Text(device.macAdress, style: TextStyle(color: Colors.grey.shade600)),
      trailing: isConnected
          ? Icon(Icons.check_circle, color: Colors.green.shade800)
          : const SizedBox.shrink(),
      onTap: () => _connectToPrinter(device.macAdress),
      tileColor: isConnected ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildInvoicePreviewSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Screenshot(
        controller: screenshotController,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceHeader(),
              const SizedBox(height: 16),
              _buildCustomerInfo(),
              Text('______________________________________'),
              const SizedBox(height: 4),
              _buildItemsList(),
              const SizedBox(height: 2),
              Text('______________________________________'),
              _buildTotals(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Center(
      child: Column(
        children: [
          Text(
            widget.orderData['company_name'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Invoice",
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          Text('______________________________________'),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow("Customer:", widget.orderData['customer_name']),
        _buildInfoRow("Salesperson:", widget.orderData['user_name']),
        _buildInfoRow("Date:", DateTime.now().toString().substring(0, 16)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Qty", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Item", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.orderData['items'].map<Widget>((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${item['quantity']}x"),
                  Text(item['name'], overflow: TextOverflow.ellipsis),
                  Text("${item['price'].toStringAsFixed(2)}"),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.indigo.shade800 : Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            "${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.indigo.shade800 : Colors.grey.shade700,
              fontSize: isTotal ? 16 : 14,
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
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.black87,
                  ),
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

  Widget _buildPrintButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(Icons.print, color: Colors.white),
        label: const Text(
          "PRINT INVOICE",
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo.shade800,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _printReceipt,
      ),
    );
  }

  Widget _buildTotals() {
    return Column(
      children: [
        _buildTotalRow("Subtotal:", widget.orderData['total_before_vat']),
        _buildTotalRow("Tax:", widget.orderData['vat_amount']),
        Text('______________________________________'),
        _buildTotalRow(
          "TOTAL:",
          widget.orderData['total_with_vat'],
          isTotal: true,
        ),
      ],
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
                      Text(" ${item['price'].toStringAsFixed(2)}"),
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
}
