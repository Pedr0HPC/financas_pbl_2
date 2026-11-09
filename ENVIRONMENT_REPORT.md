# Relatório de ambiente de execução — AP2B

- **Data de preparação:** 08/11/2026.
- **Projeto:** Flutter AP2B — Tema 06, derivado conceitualmente de https://github.com/Pedr0HPC/financas_pbl.
- **Ambiente em que os arquivos foram montados:** contêiner isolado sem Flutter SDK, Dart SDK, Android SDK ou emulador.
- **Validação possível:** conferência da estrutura de arquivos, contagem de rotas e casos de teste, análise estática aproximada de fechamento de delimitadores.
- **Não validado aqui:** resolução do Pub, `flutter analyze`, compilação Android/iOS, testes executados, chamadas de rede reais e interação com emulador.

## Passos obrigatórios na máquina do grupo

1. Instale o Flutter e configure Android Studio/SDK.
2. Execute `flutter doctor`.
3. Execute `flutter create --project-name financas_pbl_ap2b --platforms=android .` na raiz.
4. Inclua a permissão de internet no Manifest ou execute `bootstrap_android.ps1` para automatizar.
5. Execute `flutter pub get` e, em seguida, `dart format lib test`.
6. Execute `flutter analyze` e corrija erros que forem encontrados.
7. Execute `flutter test` e corrija eventuais falhas.
8. Execute `flutter run` e teste offline e online.
9. Faça commit do `pubspec.lock` gerado e das pastas da plataforma Android.
10. Registre aqui os resultados **efetivamente observados** e a versão de Flutter que utilizaram.

**Campos a preencher pelo grupo após testar:**

- Flutter (`flutter --version`): [PREENCHER]
- `flutter analyze`: [PREENCHER]
- `flutter test`: [PREENCHER]
- `flutter run`: [PREENCHER]
- Dispositivo/emulador: [PREENCHER]
- Demonstração modo avião: [PREENCHER]
