# Script de Despliegue Automático COMPLETO - iStella
# Sube APK a GitHub Releases y actualiza Firebase Remote Config automáticamente

param(
    [string]$VersionType = "patch",
    [string]$Message = "Nueva versión disponible",
    [bool]$ForceUpdate = $false
)

Write-Host "🚀 Iniciando despliegue automático COMPLETO de iStella..." -ForegroundColor Green
Write-Host ""

# Verificar dependencias
Write-Host "🔍 Verificando dependencias..." -ForegroundColor Cyan

# Verificar Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git no está instalado. Instálalo desde: https://git-scm.com" -ForegroundColor Red
    exit 1
}

# Verificar GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  GitHub CLI no está instalado." -ForegroundColor Yellow
    Write-Host "   Instalando GitHub CLI..." -ForegroundColor Cyan
    winget install --id GitHub.cli -e --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error instalando GitHub CLI" -ForegroundColor Red
        Write-Host "   Instálalo manualmente: https://cli.github.com" -ForegroundColor Yellow
        exit 1
    }
}

# Verificar Firebase CLI
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  Firebase CLI no está instalado." -ForegroundColor Yellow
    Write-Host "   Instalando Firebase CLI..." -ForegroundColor Cyan
    npm install -g firebase-tools
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error instalando Firebase CLI" -ForegroundColor Red
        exit 1
    }
}

Write-Host "   ✅ Todas las dependencias instaladas" -ForegroundColor Green

# 1. Leer versión actual
Write-Host ""
Write-Host "📖 Leyendo versión actual..." -ForegroundColor Cyan
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw

if ($pubspecContent -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = [int]$matches[4]
    
    $currentVersion = "$major.$minor.$patch"
    Write-Host "   Versión actual: $currentVersion+$build" -ForegroundColor Yellow
}
else {
    Write-Host "❌ Error: No se pudo leer la versión" -ForegroundColor Red
    exit 1
}

# 2. Incrementar versión
Write-Host ""
Write-Host "⬆️  Incrementando versión..." -ForegroundColor Cyan

$newBuild = $build + 1

switch ($VersionType) {
    "major" { $major++; $minor = 0; $patch = 0 }
    "minor" { $minor++; $patch = 0 }
    "patch" { $patch++ }
}

$newVersion = "$major.$minor.$patch"
$newVersionFull = "$newVersion+$newBuild"

Write-Host "   Nueva versión: $newVersionFull" -ForegroundColor Green

# Actualizar pubspec.yaml
$pubspecContent = $pubspecContent -replace "version:\s*\d+\.\d+\.\d+\+\d+", "version: $newVersionFull"
Set-Content -Path $pubspecPath -Value $pubspecContent -NoNewline

# 3. Compilar APK Release
Write-Host ""
Write-Host "🔨 Compilando APK Release..." -ForegroundColor Cyan
Write-Host "   (Esto puede tomar varios minutos...)" -ForegroundColor Yellow

flutter build apk --release | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ APK compilado exitosamente" -ForegroundColor Green
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    $apkSize = (Get-Item $apkPath).Length / 1MB
    Write-Host "   📦 Tamaño: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Yellow
}
else {
    Write-Host "   ❌ Error al compilar APK" -ForegroundColor Red
    exit 1
}

# 4. Crear release en GitHub
Write-Host ""
Write-Host "📤 Subiendo a GitHub Releases..." -ForegroundColor Cyan

# Verificar si hay un repositorio Git
if (-not (Test-Path ".git")) {
    Write-Host "   ⚠️  No hay repositorio Git. Inicializando..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial commit - v$newVersion"
    
    Write-Host "   📝 Crea un repositorio en GitHub y ejecuta:" -ForegroundColor Yellow
    Write-Host "      git remote add origin https://github.com/TU_USUARIO/iStella.git" -ForegroundColor White
    Write-Host "      git push -u origin main" -ForegroundColor White
    Write-Host ""
    Write-Host "   Luego vuelve a ejecutar este script." -ForegroundColor Yellow
    exit 0
}

# Commit de cambios
git add pubspec.yaml
git commit -m "chore: bump version to $newVersion" -ErrorAction SilentlyContinue

# Crear tag
git tag -a "v$newVersion" -m "$Message"

# Push
git push origin main --tags 2>&1 | Out-Null

# Crear release en GitHub con el APK
Write-Host "   Creando release v$newVersion..." -ForegroundColor Cyan

$releaseNotes = @"
# iStella v$newVersion

## 📝 Cambios

$Message

## 📥 Instalación

1. Descarga el APK adjunto
2. Permite instalación de fuentes desconocidas en tu dispositivo
3. Instala el APK

## ⚙️ Configuración

- Tipo de actualización: $(if ($ForceUpdate) { "**FORZADA** ⚠️" } else { "Opcional ℹ️" })
- Build: $newBuild

---
*Generado automáticamente*
"@

# Crear release
gh release create "v$newVersion" `
    $apkPath `
    --title "iStella v$newVersion" `
    --notes $releaseNotes `
    2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Release creado en GitHub" -ForegroundColor Green
    
    # Obtener URL del APK
    $releaseInfo = gh release view "v$newVersion" --json assets | ConvertFrom-Json
    $apkUrl = $releaseInfo.assets[0].url
    
    Write-Host "   🔗 URL del APK: $apkUrl" -ForegroundColor Yellow
}
else {
    Write-Host "   ❌ Error creando release" -ForegroundColor Red
    Write-Host "   Asegúrate de estar autenticado: gh auth login" -ForegroundColor Yellow
    exit 1
}

# 5. Actualizar Firebase Remote Config
Write-Host ""
Write-Host "🔧 Actualizando Firebase Remote Config..." -ForegroundColor Cyan

# Crear archivo JSON temporal con la configuración
$remoteConfigJson = @{
    parameters = @{
        latest_version = @{
            defaultValue = @{ value = $newVersion }
            description  = "Última versión disponible de la app"
        }
        min_version    = @{
            defaultValue = @{ value = $(if ($ForceUpdate) { $newVersion } else { $currentVersion }) }
            description  = "Versión mínima requerida"
        }
        force_update   = @{
            defaultValue = @{ value = $ForceUpdate.ToString().ToLower() }
            description  = "Si la actualización es obligatoria"
        }
        update_url     = @{
            defaultValue = @{ value = $apkUrl }
            description  = "URL de descarga del APK"
        }
        update_message = @{
            defaultValue = @{ value = $Message }
            description  = "Mensaje de actualización"
        }
    }
} | ConvertTo-Json -Depth 10

$configPath = "remote-config-temp.json"
Set-Content -Path $configPath -Value $remoteConfigJson

# Actualizar Remote Config
firebase remoteconfig:set $configPath --project istellacd 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Remote Config actualizado" -ForegroundColor Green
    Remove-Item $configPath
}
else {
    Write-Host "   ⚠️  Error actualizando Remote Config" -ForegroundColor Yellow
    Write-Host "   Asegúrate de estar autenticado: firebase login" -ForegroundColor Yellow
    Write-Host "   Configuración guardada en: $configPath" -ForegroundColor Yellow
}

# 6. Resumen final
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ DESPLIEGUE COMPLETADO AUTOMÁTICAMENTE" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Resumen:" -ForegroundColor Cyan
Write-Host "   Versión:          $newVersionFull" -ForegroundColor Green
Write-Host "   GitHub Release:   https://github.com/TU_USUARIO/iStella/releases/tag/v$newVersion" -ForegroundColor Yellow
Write-Host "   APK URL:          $apkUrl" -ForegroundColor Yellow
Write-Host "   Actualización:    $(if ($ForceUpdate) { 'FORZADA ⚠️' } else { 'Opcional ℹ️' })" -ForegroundColor $(if ($ForceUpdate) { 'Red' } else { 'Yellow' })
Write-Host ""
Write-Host "🎉 Los usuarios verán la actualización al abrir la app!" -ForegroundColor Green
Write-Host ""
