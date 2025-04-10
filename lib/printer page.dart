import 'package:flutter/material.dart';
import 'package:x_printer/x_printer.dart';

class XPrinterP323BPage extends StatefulWidget {
  const XPrinterP323BPage({super.key});

  @override
  State<XPrinterP323BPage> createState() => _XPrinterP323BPageState();
}

class _XPrinterP323BPageState extends State<XPrinterP323BPage> {
  final XPrinter _printer = XPrinter();
  List<Peripheral> _devices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  Peripheral? _connectedDevice;
  final TextEditingController _textController = TextEditingController();

  // XP-P323B specific settings
  static const _paperWidth = 80; // 80mm paper
  static const _maxCharsPerLine = 32; // Approximate for 80mm paper

  @override
  void initState() {
    super.initState();
    _setupPrinterListeners();
    _startScanning();
  }

  void _setupPrinterListeners() {
    _printer.statusStream.listen((status) {
      if (status.status == PeripheralStatus.connected) {
        setState(() => _isConnected = true);
      } else if (status.status == PeripheralStatus.disconnected) {
        setState(() => _isConnected = false);
      }
    });
  }

  Future<void> _startScanning() async {
    try {
      setState(() => _isScanning = true);
      await _printer.startScan();
    } catch (e) {
      _showError('Scanning error: ${e.toString()}');
    }
  }

  Future<void> _connectDevice(Peripheral device) async {
    try {
      await _printer.connect(device.uuid!);
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
      });
      _showMessage('Connected to ${device.name}');
    } catch (e) {
      _showError('Connection failed: ${e.toString()}');
    }
  }

  Future<void> _printTestReceipt() async {
    if (!_isConnected) {
      _showError('Not connected to printer');
      return;
    }

    try {
      // XP-P323B optimized print settings
      await _printer.printText('MY STORE',
          align: PTextAlign.center,
          attribute: PTextAttribute.bold,
          width: PTextW.w2,
          height: PTextH.h2);

      await _printer.printText('123 Business Rd\nCity, State 10001',
          align: PTextAlign.center);

      await _printer.printText('=' * _maxCharsPerLine);

      // Print items with column alignment
      await _printTwoColumns('ITEM', 'PRICE');
      await _printTwoColumns('Product 1', '\$10.00');
      await _printTwoColumns('Product 2', '\$15.50');
      await _printTwoColumns('Discount', '-\$2.00');

      await _printer.printText('=' * _maxCharsPerLine);

      await _printTwoColumns('你好 你好 ', '\$23.50', bold: true);

      await _printer.printText('\nThank you for your purchase!\n',
          align: PTextAlign.center);

      // Print QR code for store website
      await _printer.printQrCode('https://mystore.com',
          unitSize: 6, errLevel: QRErrLevel.H);

      await _printer.printText('\n\n'); // Add some blank lines
      await _printer.cutPaper();

      _showMessage('Receipt printed successfully');
    } catch (e) {
      _showError('Print failed: ${e.toString()}');
    }
  }

  Future<void> _printTwoColumns(String left, String right,
      {bool bold = false}) async {
    final maxLeftWidth =
        _maxCharsPerLine - 10; // Reserve 10 chars for right column
    final leftText = left.length > maxLeftWidth
        ? left.substring(0, maxLeftWidth)
        : left.padRight(maxLeftWidth);

    await _printer.printText('$leftText$right',
        attribute: bold ? PTextAttribute.bold : PTextAttribute.normal);
  }

  Future<void> _printCustomText() async {
    if (_textController.text.isEmpty) return;

    await _printer.printText(_textController.text, align: PTextAlign.left);
    _textController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XPrinter XP-P323B'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startScanning,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      _isConnected
                          ? 'CONNECTED TO: ${_connectedDevice?.name ?? 'Unknown'}'
                          : 'NOT CONNECTED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    if (_isConnected)
                      TextButton(
                        onPressed: _printer.disconnect,
                        child: const Text('Disconnect'),
                      ),
                  ],
                ),
              ),
            ),

            // Device List
            const SizedBox(height: 16),
            const Text('Available Printers:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Peripheral>>(
                stream: _printer.peripheralsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _devices = snapshot.data!;
                    return ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return Card(
                          child: ListTile(
                            title: Text(device.name ?? 'Unknown Device'),
                            subtitle: Text(device.uuid ?? ''),
                            trailing: _isConnected &&
                                    device.uuid == _connectedDevice?.uuid
                                ? const Icon(Icons.check, color: Colors.green)
                                : const Icon(Icons.print),
                            onTap: () => _connectDevice(device),
                          ),
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),

            // Print Controls
            const SizedBox(height: 20),
            if (_isConnected) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.receipt),
                label: const Text('Print Test Receipt'),
                onPressed: _printTestReceipt,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.cut),
                label: const Text('Cut Paper'),
                onPressed: _printer.cutPaper,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const Text('Custom Text:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _printCustomText,
                  ),
                  hintText: 'Enter text to print',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _printer.disconnect();
    _printer.stopScan();
    _textController.dispose();
    super.dispose();
  }
}
