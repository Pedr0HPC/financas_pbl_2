import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:financas_pbl_ap2b/datasources/remote_api.dart';
import 'helpers/fakes.dart';

void main() {
  group('HTTP REST com MockClient (sem internet)', () {
    test('44 - GET de cotação serializa pares reais', () async {
      final api = HttpFinanceApi(client: MockClient((request) async {
        expect(request.method, 'GET');
        return http.Response(
            jsonEncode({
              'USDBRL': {'bid': '5.20'},
              'EURBRL': {'bid': '6.18'}
            }),
            200);
      }));
      final data = await api.buscarCotacoes();
      expect(data.length, 2);
      expect(data.first.valor, 5.2);
    });

    test('45 - GET HTTP 500 é uma falha tratável', () async {
      final api = HttpFinanceApi(
          client: MockClient((request) async => http.Response('Falha', 500)));
      await expectLater(api.buscarCotacoes(), throwsA(isA<StateError>()));
    });

    test('46 - resposta com cotação inválida é rejeitada', () async {
      final api = HttpFinanceApi(
          client: MockClient((request) async => http.Response(
              '{"USDBRL":{"bid":"abc"},"EURBRL":{"bid":"6"}}', 200)));
      await expectLater(api.buscarCotacoes(), throwsFormatException);
    });

    test('47 - lançamento novo usa POST', () async {
      final api = HttpFinanceApi(client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
            request.headers.values.any((v) => v.contains('application/json')),
            isTrue);
        return http.Response('{"id":101}', 201);
      }));
      await api.enviarLancamento(lancamento());
    });

    test('48 - lançamento editado usa PUT', () async {
      final api = HttpFinanceApi(client: MockClient((request) async {
        expect(request.method, 'PUT');
        return http.Response('{}', 200);
      }));
      await api.enviarLancamento(lancamento(revisao: 2));
    });

    test('49 - tombstone utiliza DELETE', () async {
      final api = HttpFinanceApi(client: MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response('', 200);
      }));
      await api.enviarLancamento(lancamento(excluido: true));
    });

    test('50 - erro HTTP no POST impede confirmação', () async {
      final api = HttpFinanceApi(
          client: MockClient((request) async => http.Response('', 500)));
      await expectLater(
          api.enviarLancamento(lancamento()), throwsA(isA<StateError>()));
    });
  });
}
