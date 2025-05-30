import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:odoo/login/login_ui.dart';
import 'package:odoo/print_bluetooth_thermal.dart';
import 'package:odoo/printer%20page.dart';
import 'package:odoo/test.dart';
import 'package:odoo/testttt.dart';
import 'package:pretty_bloc_observer/pretty_bloc_observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:x_printer/x_printer.dart';

import '../lib/blth.dart';
import '../lib/bluetooth_print_page.dart';
import '../lib/localization.dart'; // Add this import

void main() {
  Bloc.observer = PrettyBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = XPrinter();
  final contentController = TextEditingController();

  bool _isConnected = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _getCurrentState();
      },
    );

    _plugin.statusStream.listen((event) {
      print(">>> status: ${event.status.name}");
      _getCurrentState();
    });
  }

  void _getCurrentState() {
    _plugin.isConnected.then((value) {
      print(">>> isConnected: $value");
      setState(() {
        _isConnected = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('XPrinter Plugin Example'),
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: StreamBuilder<PrinterStatus>(
                    stream: _plugin.statusStream,
                    builder: (context, snapshot) {
                      if (snapshot.data == null) {
                        return Column(
                          children: [
                            _isConnected
                                ? const Text('connected')
                                : const Text('disconnected'),
                            if (_isConnected) _buildDisconnectButton(),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Text('${snapshot.data?.status.name}'),
                          if (snapshot.data?.status ==
                              PeripheralStatus.connected)
                            _buildDisconnectButton(),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Builder(builder: (context) {
                    return TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) {
                          return SelectDevice(plugin: _plugin);
                        }));
                      },
                      child: const Text('Select Device'),
                    );
                  }),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextFormField(
                controller: contentController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Content',
                ),
                minLines: 2,
                maxLines: 5,
              ),
            ),
            Expanded(child: Container()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _printText,
                    child: const Text('Print Text'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _selectImage,
                    child: const Text('Print Image'),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _cutPaper,
                    child: const Text('Cut Paper'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _printExample,
                    child: const Text('Print Example'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextButton _buildDisconnectButton() {
    return TextButton(
      onPressed: () {
        _plugin.disconnect();
      },
      child: const Text('Disconnect'),
    );
  }

  void _printText() {
    _plugin.printText(contentController.text);
  }

  void _cutPaper() {
    _plugin.cutPaper();
  }

  void _printExample() {
    _plugin.printText('=======================================');
    _plugin.printText("Left");
    _plugin.printText(
      "Center",
      align: PTextAlign.center,
    );
    _plugin.printText(
      "Right",
      align: PTextAlign.right,
    );

    _plugin.printText('=======================================');
    _plugin.printText("FontB", attribute: PTextAttribute.fontB);
    _plugin.printText("Bold", attribute: PTextAttribute.bold);
    _plugin.printText(
      "Underline",
      attribute: PTextAttribute.underline,
    );
    _plugin.printText(
      "Underline2",
      attribute: PTextAttribute.underline2,
    );
    _plugin.printText('=======================================');
    _plugin.printText(
      "W1",
      width: PTextW.w2,
      height: PTextH.h2,
    );
    _plugin.printText(
      "W2",
      width: PTextW.w2,
      height: PTextH.h2,
    );
    _plugin.printText(
      "W3",
      width: PTextW.w3,
      height: PTextH.h3,
    );
    _plugin.printText(
      "W4",
      width: PTextW.w4,
      height: PTextH.h4,
    );

    _plugin.cutPaper();
  }

  void _selectImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _printImage(image);
    }
  }

  void _printImage(XFile file) async {
    final img.Image? image = img.decodeImage(await file.readAsBytes());

    if (image != null) {
      final img.Image resizedImage = img.copyResize(image, width: 460);

      final List<int> compressedImage = img.encodePng(resizedImage);

      final String base64Image = base64Encode(compressedImage);

      _plugin.printImage(base64Image, width: 460);
      _plugin.cutPaper();
    } else {
      print('Failed to decode image');
    }
  }
}
