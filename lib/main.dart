import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';

void main() {
  runApp(CatFoodCheckApp());
}

class CatFoodCheckApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CatFoodCheck',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ScanPage(),
    );
  }
}

class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String resultText = "";

  Future<void> scanAndCheck() async {
    try {
      var scanResult = await BarcodeScanner.scan();
      String ean = scanResult.rawContent;

      if (ean.isEmpty) return;

      final response = await http
          .get(Uri.parse('https://catfoodcheck.onrender.com/scan/$ean'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          if (data['wsava'] == true) {
            resultText =
                "${data['brand']} ${data['product']}\n✅ Cumple WSAVA";
          } else {
            resultText =
                "${data['brand']} ${data['product']}\n❌ No cumple WSAVA";
          }
        });
      } else {
        setState(() {
          resultText = "Error fetching product info";
        });
      }
    } catch (e) {
      setState(() {
        resultText = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CatFoodCheck")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: scanAndCheck, child: Text("Scan Cat Food")),
            SizedBox(height: 20),
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}