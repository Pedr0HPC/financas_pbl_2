#!/usr/bin/env python3
"""Adapta o projeto Financas PBL AP2B para execucao Flutter Web com SQLite/IndexedDB.

Requer a dependencia sqflite_common_ffi_web, instalada com:
    flutter pub add sqflite_common_ffi_web
Execute a partir da raiz (com pubspec.yaml): python3 ativar_web.py
Nao altera business rules, fluxos do Repository nem a plataforma Android.
Nao faz commit nem mascara resultados de testes.
"""
from pathlib import Path
import re
import sys

root = Path.cwd()
main_path = root / 'lib/main.dart'
store_path = root / 'lib/datasources/local_store.dart'
if not (root / 'pubspec.yaml').is_file() or not main_path.is_file() or not store_path.is_file():
    sys.exit('ERRO: execute na raiz do projeto Flutter com lib/main.dart e lib/datasources/local_store.dart.')

main_original = main_path.read_text(encoding='utf-8')
store_original = store_path.read_text(encoding='utf-8')
main = main_original
store = store_original

if 'sqflite_common_ffi_web:' not in (root / 'pubspec.yaml').read_text(encoding='utf-8'):
    sys.exit('ERRO: primeiro execute flutter pub add sqflite_common_ffi_web.')

if "import 'package:flutter/foundation.dart' show kIsWeb;" not in main:
    marker = "import 'package:flutter/material.dart';"
    if marker not in main:
        sys.exit('ERRO: nao foi encontrado o import de material.dart em lib/main.dart.')
    imports = """import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' show databaseFactoryFfiWeb;
"""
    main = main.replace(marker, imports + marker, 1)
else:
    for s in ('databaseFactoryFfiWeb', 'databaseFactory'):
        if s not in main:
            sys.exit('ERRO: main.dart ja foi parcialmente editado. Revise antes de aplicar.')

if 'databaseFactory = databaseFactoryFfiWeb;' not in main:
    match = re.search(r'(Future<void>\s+main\(\)\s+async\s*\{\s*WidgetsFlutterBinding\.ensureInitialized\(\);)', main)
    if match is None:
        sys.exit('ERRO: nao foi encontrada a inicializacao main() esperada; nenhuma alteracao salva.')
    pos = match.end()
    main = main[:pos] + '\n  if (kIsWeb) {\n    databaseFactory = databaseFactoryFfiWeb;\n  }' + main[pos:]

if "import 'package:flutter/foundation.dart' show kIsWeb;" not in store:
    marker = "import 'package:path/path.dart';"
    if marker not in store:
        sys.exit('ERRO: import de path.dart nao encontrado no armazenamento; nenhuma alteracao salva.')
    store = store.replace(marker, "import 'package:flutter/foundation.dart' show kIsWeb;\n" + marker, 1)

if "? 'financas_ap2b.db'" not in store:
    pat = re.compile(
        r"(?P<indent>^[ \t]*)final\s+base\s*=\s*await\s+getDatabasesPath\(\);\s*"
        r"_db\s*=\s*await\s+openDatabase\(\s*join\(\s*base\s*,\s*'financas_ap2b\.db'\s*\)\s*,",
        flags=re.MULTILINE,
    )
    m = pat.search(store)
    if m is None:
        sys.exit('ERRO: padrao de abertura SQLite nao encontrado. Nenhuma alteracao salva. Envie lib/datasources/local_store.dart para ajuste manual.')
    indent = m.group('indent')
    replacement = (f"{indent}final databasePath = kIsWeb\n"
                   f"{indent}    ? 'financas_ap2b.db'\n"
                   f"{indent}    : join(await getDatabasesPath(), 'financas_ap2b.db');\n"
                   f"{indent}_db = await openDatabase(databasePath,")
    store = store[:m.start()] + replacement + store[m.end():]

if main != main_original:
    main_path.write_text(main, encoding='utf-8')
    print('[OK] lib/main.dart adaptado para a fabrica SQLite Web')
else:
    print('[OK] lib/main.dart ja adaptado')
if store != store_original:
    store_path.write_text(store, encoding='utf-8')
    print('[OK] lib/datasources/local_store.dart adaptado para caminho Web')
else:
    print('[OK] lib/datasources/local_store.dart ja adaptado')

print('''\nAgora execute:\n  dart format lib/main.dart lib/datasources/local_store.dart\n  flutter analyze\n  flutter test\n  flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080\nNo Codespaces abra a URL da porta 8080 em PORTS.\n''')
