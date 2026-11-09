#!/usr/bin/env python3
"""Correcoes pontuais para AP2B Tema 06, conforme log de 09/11/2026.
Execute na raiz do projeto: python3 corrigir_ap2b.py
Nao executa commit, pub get, format, analyze ou test automaticamente.
"""
from pathlib import Path
import re
import sys

root = Path.cwd()
if not (root / 'pubspec.yaml').is_file() or not (root / 'lib').is_dir():
    sys.exit('ERRO: execute a partir da raiz do app Flutter (pasta com pubspec.yaml).')

errors = []
changed = []

def patch(path, fn):
    target = root / path
    if not target.is_file():
        errors.append(f'Arquivo ausente: {path}')
        return
    source = target.read_text(encoding='utf-8')
    modified = fn(source, path)
    if modified is None:
        return
    if source != modified:
        target.write_text(modified, encoding='utf-8')
        changed.append(path)
        print(f'[CORRIGIDO] {path}')
    else:
        print(f'[OK] {path} (sem alteracoes necessarias)')

# 1. R$ dentro de strings Dart deve ser R\$ para nao iniciar interpolacao.
def fix_real(source, name):
    count = source.count('R$)')
    if count:
        print(f'  - Escapando {count} ocorrencia(s) de R$ em {name}')
        return source.replace('R$)', r'R\$)')
    if r'R\$)' not in source:
        errors.append(f'Nao foi localizada a string esperada em {name}; revise manualmente.')
    return source

for relative in (
    'lib/screens/extra_screens.dart',
    'lib/screens/goals_screen.dart',
    'lib/screens/transaction_form_screen.dart',
):
    patch(relative, fix_real)

# 2. Corrige o teste 15: o segundo lancamento precisa ser receita.
def fix_sum(source, name):
    pat = re.compile(r"lancamento\(\s*id:\s*'b'\s*,\s*valorCentavos:\s*8000\s*\)")
    replacement = "lancamento(id: 'b', tipo: 'receita', valorCentavos: 8000)"
    modified, hits = pat.subn(replacement, source)
    if hits == 0 and replacement not in source:
        errors.append(f'Teste 15 nao localizado no formato previsto em {name}; revise manualmente.')
    return modified
patch('test/domain_test.dart', fix_sum)

# 3. Catch deve aguardar tambem o Future de leitura local no try.
def fix_future(source, name):
    old = 'return local.cotacoes();'
    if old in source:
        return source.replace(old, 'return await local.cotacoes();')
    if 'return await local.cotacoes();' not in source:
        errors.append(f'Retorno de cotacoes nao encontrado em {name}.')
    return source
patch('lib/repositories/finance_repository.dart', fix_future)

# 4. Flutter create gera um teste padrao para MyApp, nao existente neste app.
generated_test = root / 'test/widget_test.dart'
if generated_test.is_file():
    content = generated_test.read_text(encoding='utf-8')
    if 'MyApp' in content and content.count('testWidgets(') == 1:
        generated_test.unlink()
        changed.append('test/widget_test.dart (teste template removido)')
        print('[CORRIGIDO] test/widget_test.dart - teste do contador gerado pelo Flutter removido')
    elif 'MyApp' in content:
        errors.append('test/widget_test.dart usa MyApp, mas foi personalizado; revise manualmente.')
    else:
        print('[OK] test/widget_test.dart nao faz referencia a MyApp')
else:
    print('[OK] test/widget_test.dart nao existe')

# 5. Permissao da rede no AndroidManifest (se a plataforma ja foi gerada).
manifest = root / 'android/app/src/main/AndroidManifest.xml'
if manifest.is_file():
    contents = manifest.read_text(encoding='utf-8')
    permission = '<uses-permission android:name="android.permission.INTERNET" />'
    if 'android.permission.INTERNET' not in contents:
        # Insere somente depois do cabecalho <manifest...>, inclusive com multiplas linhas.
        modified, hits = re.subn(
            r'(<manifest\b[^>]*>)',
            lambda m: m.group(1) + '\n    ' + permission,
            contents,
            count=1,
        )
        if hits == 1:
            manifest.write_text(modified, encoding='utf-8')
            changed.append('android/app/src/main/AndroidManifest.xml')
            print('[CORRIGIDO] AndroidManifest.xml - permissao INTERNET')
        else:
            errors.append('Nao foi possivel adicionar permissao INTERNET ao AndroidManifest.xml.')
    else:
        print('[OK] AndroidManifest.xml ja tem permissao INTERNET')
else:
    print('[ATENCAO] android/app/src/main/AndroidManifest.xml ausente; gere Android primeiro.')

print('\nResumo: ' + (', '.join(changed) if changed else 'nenhum arquivo modificado'))
if errors:
    print('\nVERIFICACAO MANUAL NECESSARIA:')
    for message in errors:
        print(' - ' + message)
    sys.exit(1)
print('\nProximos comandos:')
print('  dart fix --dry-run')
print('  dart fix --apply --code=curly_braces_in_flow_control_structures')
print('  dart format lib test')
print('  flutter analyze')
print('  flutter test')
