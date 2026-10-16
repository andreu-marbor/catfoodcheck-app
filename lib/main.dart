import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

/// Resultado tipado de la consulta a la API del backend CatFoodCheck.
sealed class ScanResult {
  const ScanResult();

  /// Texto que se muestra en la interfaz para este resultado.
  String get message;
}

final class ProductResult extends ScanResult {
  const ProductResult(this.product, this.brand, this.wsava);

  final String product;
  final String brand;
  final bool wsava;

  @override
  String get message =>
      '$product\nBrand: $brand\nWSAVA: ${wsava ? "✅ Yes" : "❌ No"}';
}

final class NotFoundResult extends ScanResult {
  const NotFoundResult();

  @override
  String get message => 'Product not found';
}

final class TimeoutResult extends ScanResult {
  const TimeoutResult();

  @override
  String get message => 'Request timed out, try again';
}

final class NetworkErrorResult extends ScanResult {
  const NetworkErrorResult();

  @override
  String get message => 'Error connecting to API';
}

final class InvalidBodyResult extends ScanResult {
  const InvalidBodyResult();

  @override
  String get message => 'Unexpected server response';
}

/// Consulta el producto [barcode] en el backend CatFoodCheck.
///
/// Nunca lanza: cualquier fallo se devuelve como un [ScanResult] de error.
/// [timeout] es configurable para los tests; en producción 15 s es suficiente
/// para despertar al backend de Render (free tier se duerme).
Future<ScanResult> fetchProduct(
  http.Client client,
  String barcode, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final uri = Uri.parse('https://catfoodcheck.onrender.com/scan/$barcode');

  final http.Response response;
  try {
    response = await client.get(uri).timeout(timeout);
  } on TimeoutException {
    return const TimeoutResult();
  } catch (_) {
    return const NetworkErrorResult();
  }

  if (response.statusCode == 404) return const NotFoundResult();
  if (response.statusCode != 200) return const NetworkErrorResult();

  try {
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return const InvalidBodyResult();

    final product = data['product'];
    final brand = data['brand'];
    final wsava = data['wsava'];
    if (product is! String || brand is! String || wsava is! bool) {
      return const InvalidBodyResult();
    }
    return ProductResult(product, brand, wsava);
  } on FormatException {
    return const InvalidBodyResult();
  }
}

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
  const ScannerPage({super.key, this.client});

  /// Cliente HTTP inyectable (para tests); si se omite se crea uno propio.
  final http.Client? client;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late final http.Client _client = widget.client ?? http.Client();

  // Solo formatos de comida para mascota: menos trabajo de ML Kit y
  // detección más rápida que escanear todas las symbologies.
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 500,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  /// true = hay un escaneo en curso o un resultado sin descartar.
  /// Evita que la cámara re-llame a la API con el mismo código en bucle:
  /// solo se reinicia al pulsar "Scan again".
  bool _scanned = false;
  bool _loading = false;
  String _resultText = 'Scan a cat food barcode';

  Future<void> _lookup(String barcode) async {
    final result = await fetchProduct(_client, barcode);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _resultText = result.message;
    });
  }

  void onDetect(BarcodeCapture capture) {
    if (_scanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _scanned = true;
      _loading = true;
    });
    _lookup(code);
  }

  void _resetScan() {
    setState(() {
      _scanned = false;
      _resultText = 'Scan a cat food barcode';
    });
  }

  Widget _buildScannerError(
    BuildContext context,
    MobileScannerException error,
    Widget? child,
  ) {
    final permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          permissionDenied ? 'Camera permission denied' : 'Camera unavailable',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    if (_loading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Looking up product…',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _resultText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        if (_scanned) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _resetScan,
            child: const Text('Scan again'),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CatFoodCheck'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: _controller,
              onDetect: onDetect,
              errorBuilder: _buildScannerError,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildResultPanel(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
