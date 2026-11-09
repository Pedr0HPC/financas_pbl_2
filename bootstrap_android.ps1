# Execute dentro da raiz do projeto AP2B com Flutter instalado no PATH.
$ErrorActionPreference = 'Stop'
flutter doctor
flutter create --project-name financas_pbl_ap2b --platforms=android .
if ($LASTEXITCODE -ne 0) { throw 'Falha ao gerar arquivos Android.' }
$manifest = 'android/app/src/main/AndroidManifest.xml'
if (-not (Test-Path $manifest)) { throw 'Manifest Android não encontrado.' }
$content = Get-Content -Raw -Path $manifest
if ($content -notmatch 'android.permission.INTERNET') {
    $insert = '<uses-permission android:name="android.permission.INTERNET" />' + "`n    <application"
    $content = $content.Replace('<application', $insert)
    Set-Content -Path $manifest -Value $content -Encoding UTF8
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Falha em flutter pub get.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Falha no flutter analyze. Corrija antes da entrega.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Falha nos testes. Corrija antes da entrega.' }
Write-Host 'Plataforma Android e validações concluídas. Execute: flutter run'
