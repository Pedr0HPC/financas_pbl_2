import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/finance_models.dart';

abstract class RemoteFinanceApi {
  Future<List<Cotacao>> buscarCotacoes();
  Future<void> enviarLancamento(Lancamento item);
}

class HttpFinanceApi implements RemoteFinanceApi {
  final http.Client client;
  final Duration timeout;
  HttpFinanceApi(
      {required this.client, this.timeout = const Duration(seconds: 5)});

  // Endpoint público real para cotação de moedas.
  static final urlCotacoes =
      Uri.parse('https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL');
  // Endpoint de DEMONSTRAÇÃO sem armazenamento persistente de registros financeiros.
  static final urlMock =
      Uri.parse('https://jsonplaceholder.typicode.com/posts');

  @override
  Future<List<Cotacao>> buscarCotacoes() async {
    final response = await client.get(urlCotacoes).timeout(timeout);
    if (response.statusCode != 200) {
      throw StateError('API de câmbio retornou HTTP ${response.statusCode}.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final now = DateTime.now();
    return ['USDBRL', 'EURBRL'].map((par) {
      final objeto = json[par] as Map<String, dynamic>?;
      if (objeto == null) throw const FormatException('Par ausente na API.');
      final numero = double.tryParse(objeto['bid'].toString());
      if (numero == null || numero <= 0) {
        throw const FormatException('Cotação inválida.');
      }
      return Cotacao(par: par, valor: numero, atualizadoEm: now);
    }).toList();
  }

  @override
  Future<void> enviarLancamento(Lancamento item) async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    late final http.Response response;
    if (item.excluido) {
      response = await client
          .delete(Uri.parse('${urlMock.toString()}/1'), headers: headers)
          .timeout(timeout);
    } else if (item.revisao > 1) {
      response = await client
          .put(Uri.parse('${urlMock.toString()}/1'),
              headers: headers, body: item.toJson())
          .timeout(timeout);
    } else {
      response = await client
          .post(urlMock, headers: headers, body: item.toJson())
          .timeout(timeout);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'API de demonstração retornou HTTP ${response.statusCode}.');
    }
  }
}
