import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/finance_models.dart';

/// Contrato substituível por fakes, permitindo testes sem SQLite/emulador.
abstract class LocalStore {
  Future<List<Categoria>> categorias();
  Future<void> salvarCategoria(Categoria item);
  Future<void> excluirCategoria(String id);
  Future<List<Lancamento>> lancamentos({bool incluirExcluidos = false});
  Future<List<Lancamento>> pendentes();
  Future<void> salvarLancamento(Lancamento item);
  Future<void> marcarExcluido(String id);
  Future<bool> confirmarSync(String id, int revisao);
  Future<List<MetaFinanceira>> metas();
  Future<void> salvarMeta(MetaFinanceira item);
  Future<void> excluirMeta(String id);
  Future<void> salvarCotacoes(List<Cotacao> itens);
  Future<List<Cotacao>> cotacoes();
  Future<void> logSync(String mensagem);
  Future<List<String>> logs();
}

class SqliteStore implements LocalStore {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final base = await getDatabasesPath();
    _db = await openDatabase(
      join(base, 'financas_ap2b.db'),
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE categorias (
          id TEXT PRIMARY KEY, nome TEXT NOT NULL UNIQUE,
          limite_centavos INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''CREATE TABLE lancamentos (
          id TEXT PRIMARY KEY, descricao TEXT NOT NULL,
          valor_centavos INTEGER NOT NULL CHECK(valor_centavos > 0),
          tipo TEXT NOT NULL CHECK(tipo IN ('receita','despesa')),
          categoria_id TEXT NOT NULL REFERENCES categorias(id),
          data TEXT NOT NULL, sincronizado INTEGER NOT NULL DEFAULT 0,
          excluido INTEGER NOT NULL DEFAULT 0, revisao INTEGER NOT NULL DEFAULT 1)''');
        await db.execute(
            'CREATE INDEX idx_pendentes ON lancamentos(sincronizado,excluido)');
        await db.execute('''CREATE TABLE metas (
          id TEXT PRIMARY KEY, nome TEXT NOT NULL, alvo_centavos INTEGER NOT NULL,
          acumulado_centavos INTEGER NOT NULL, prazo TEXT NOT NULL)''');
        await db.execute('''CREATE TABLE cotacoes (
          par TEXT PRIMARY KEY, valor REAL NOT NULL, atualizado_em TEXT NOT NULL)''');
        await db.execute('''CREATE TABLE logs_sync (
          id INTEGER PRIMARY KEY AUTOINCREMENT, mensagem TEXT NOT NULL,
          criado_em TEXT NOT NULL)''');
        final batch = db.batch();
        for (final c in const [
          Categoria(id: 'geral', nome: 'Geral'),
          Categoria(id: 'salario', nome: 'Salário'),
          Categoria(id: 'alimentacao', nome: 'Alimentação'),
          Categoria(id: 'transporte', nome: 'Transporte'),
          Categoria(id: 'moradia', nome: 'Moradia'),
          Categoria(id: 'saude', nome: 'Saúde'),
          Categoria(id: 'educacao', nome: 'Educação'),
          Categoria(id: 'lazer', nome: 'Lazer'),
          Categoria(id: 'outros', nome: 'Outros'),
        ]) {
          batch.insert('categorias', c.toMap());
        }
        await batch.commit(noResult: true);
      },
    );
    return _db!;
  }

  @override
  Future<List<Categoria>> categorias() async =>
      (await (await database).query('categorias', orderBy: 'nome ASC'))
          .map(Categoria.fromMap)
          .toList();

  @override
  Future<void> salvarCategoria(Categoria item) async {
    final db = await database;
    await db.insert('categorias', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.update('categorias', item.toMap(),
        where: 'id=?', whereArgs: [item.id]);
  }

  @override
  Future<void> excluirCategoria(String id) async {
    final count = await (await database)
        .delete('categorias', where: 'id=?', whereArgs: [id]);
    if (count == 0) throw StateError('Categoria inexistente.');
  }

  @override
  Future<List<Lancamento>> lancamentos({bool incluirExcluidos = false}) async =>
      (await (await database).query('lancamentos',
              where: incluirExcluidos ? null : 'excluido=0',
              orderBy: 'data DESC'))
          .map(Lancamento.fromMap)
          .toList();

  @override
  Future<List<Lancamento>> pendentes() async => (await (await database)
          .query('lancamentos', where: 'sincronizado=0', orderBy: 'data ASC'))
      .map(Lancamento.fromMap)
      .toList();

  @override
  Future<void> salvarLancamento(Lancamento item) async {
    await (await database).insert('lancamentos', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> marcarExcluido(String id) async {
    final count =
        await (await database).rawUpdate('''UPDATE lancamentos SET excluido=1,
      sincronizado=0, revisao=revisao+1 WHERE id=? AND excluido=0''', [id]);
    if (count == 0) throw StateError('Lançamento não encontrado.');
  }

  /// Evita marcar sincronizada uma versão alterada enquanto a rede respondia.
  @override
  Future<bool> confirmarSync(String id, int revisao) async =>
      (await (await database).update('lancamentos', {'sincronizado': 1},
          where: 'id=? AND revisao=?', whereArgs: [id, revisao])) ==
      1;

  @override
  Future<List<MetaFinanceira>> metas() async =>
      (await (await database).query('metas', orderBy: 'prazo ASC'))
          .map(MetaFinanceira.fromMap)
          .toList();

  @override
  Future<void> salvarMeta(MetaFinanceira item) async {
    await (await database).insert('metas', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> excluirMeta(String id) async {
    await (await database).delete('metas', where: 'id=?', whereArgs: [id]);
  }

  @override
  Future<List<Cotacao>> cotacoes() async =>
      (await (await database).query('cotacoes')).map(Cotacao.fromMap).toList();

  @override
  Future<void> salvarCotacoes(List<Cotacao> itens) async {
    final batch = (await database).batch();
    for (final item in itens) {
      batch.insert('cotacoes', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> logSync(String mensagem) async {
    await (await database).insert('logs_sync', {
      'mensagem': mensagem,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<String>> logs() async =>
      (await (await database).query('logs_sync', orderBy: 'id DESC', limit: 50))
          .map((row) => '${row['criado_em']}: ${row['mensagem']}')
          .toList();
}
