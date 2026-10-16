import 'package:catfoodcheck_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('fetchProduct', () {
    test('devuelve ProductResult cuando wsava es true', () async {
      final client = MockClient((request) async => http.Response(
            '{"product": "Sterilised 37", "brand": "Royal Canin", "wsava": true}',
            200,
            headers: {'content-type': 'application/json'},
          ));

      final result = await fetchProduct(client, '1234567890123');

      expect(result, isA<ProductResult>());
      expect(result.message, contains('Royal Canin'));
      expect(result.message, contains('✅ Yes'));
    });

    test('devuelve ProductResult cuando wsava es false', () async {
      final client = MockClient((request) async => http.Response(
            '{"product": "Pienso", "brand": "Marca X", "wsava": false}',
            200,
            headers: {'content-type': 'application/json'},
          ));

      final result = await fetchProduct(client, '1234567890123');

      expect(result, isA<ProductResult>());
      expect(result.message, contains('❌ No'));
    });

    test('devuelve InvalidBodyResult si wsava viene null (bug conocido)', () async {
      final client = MockClient((request) async => http.Response(
            '{"product": "Pienso", "brand": "Marca X", "wsava": null}',
            200,
            headers: {'content-type': 'application/json'},
          ));

      final result = await fetchProduct(client, '1234567890123');

      expect(result, isA<InvalidBodyResult>());
    });

    test('devuelve InvalidBodyResult si el cuerpo no es JSON válido', () async {
      final client = MockClient(
        (request) async => http.Response('<html>error</html>', 200),
      );

      final result = await fetchProduct(client, '1234567890123');

      expect(result, isA<InvalidBodyResult>());
    });

    test('devuelve NotFoundResult ante un 404', () async {
      final client = MockClient(
        (request) async => http.Response('not found', 404),
      );

      final result = await fetchProduct(client, '0000000000000');

      expect(result, isA<NotFoundResult>());
      expect(result.message, 'Product not found');
    });

    test('devuelve NetworkErrorResult si la petición lanza', () async {
      final client = MockClient(
        (request) async => throw http.ClientException('sin red'),
      );

      final result = await fetchProduct(client, '1234567890123');

      expect(result, isA<NetworkErrorResult>());
    });

    test('devuelve TimeoutResult si el backend tarda demasiado', () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      });

      final result = await fetchProduct(
        client,
        '1234567890123',
        timeout: const Duration(milliseconds: 10),
      );

      expect(result, isA<TimeoutResult>());
    });

    test('construye la URL del endpoint correctamente', () async {
      Uri? requested;
      final client = MockClient((request) async {
        requested = request.url;
        return http.Response('{"product": "P", "brand": "B", "wsava": true}', 200);
      });

      await fetchProduct(client, '8412345678901');

      expect(requested, Uri.parse('https://catfoodcheck.onrender.com/scan/8412345678901'));
    });
  });
}
