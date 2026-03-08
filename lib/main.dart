import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CatFoodCheckApp());
}

class CatFoodCheckApp extends StatelessWidget {
  const CatFoodCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CatFoodCheck',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const ScannerPage(),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool scanned = false;
  String resultText = "Scan a cat food barcode";

  Future<void> fetchProduct(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse("https://catfoodcheck.onrender.com/scan/$barcode"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          resultText =
              "${data['product']}\nBrand: ${data['brand']}\nWSAVA: ${data['wsava'] ? "✅ Yes" : "❌ No"}";
        });
      } else {
        setState(() {
          resultText = "Product not found";
        });
      }
    } catch (e) {
      setState(() {
        resultText = "Error connecting to API";
      });
    }

    scanned = false;
  }

  void onDetect(BarcodeCapture capture) {
    if (scanned) return;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;

      if (code != null) {
        scanned = true;
        fetchProduct(code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CatFoodCheck"),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: onDetect,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  resultText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}