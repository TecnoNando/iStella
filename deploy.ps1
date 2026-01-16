# Script de Despliegue Automatico COMPLETO - iStella
# Version con API de GitHub (sin necesidad de gh CLI)

param(
    [string]$VersionType = "patch",
    [string]$Message = "Nueva version disponible",
    [bool]$ForceUpdate = $false,
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

Write-Host "Iniciando despliegue automatico de iStella..." -ForegroundColor Green
Write-Host ""

# Verificar token de GitHub
$SkipRelease = $false
if (-not $GitHubToken) {
    Write-Host "ADVERTENCIA: Token de GitHub no configurado. Se omitirá la creación del Release en GitHub." -ForegroundColor Yellow
    $SkipRelease = $true
}

# 1. Leer version actual
Write-Host "Leyendo version actual..." -ForegroundColor Cyan
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw

if ($pubspecContent -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = [int]$matches[4]
    
    $currentVersion = "$major.$minor.$patch"
    Write-Host "   Version actual: $currentVersion+$build" -ForegroundColor Yellow
}
else {
    Write-Host "ERROR: No se pudo leer la version" -ForegroundColor Red
    exit 1
}

# 2. Incrementar version
Write-Host ""
Write-Host "Incrementando version..." -ForegroundColor Cyan

$newBuild = $build + 1

switch ($VersionType) {
    "major" { $major++; $minor = 0; $patch = 0 }
    "minor" { $minor++; $patch = 0 }
    "patch" { $patch++ }
}

$newVersion = "$major.$minor.$patch"
$newVersionFull = "$newVersion+$newBuild"

Write-Host "   Nueva version: $newVersionFull" -ForegroundColor Green

# Actualizar pubspec.yaml
$pubspecContent = $pubspecContent -replace "version:\s*\d+\.\d+\.\d+\+\d+", "version: $newVersionFull"
Set-Content -Path $pubspecPath -Value $pubspecContent -NoNewline

# 3. Compilar APK Release
Write-Host ""
Write-Host "Compilando APK Release..." -ForegroundColor Cyan
Write-Host "   (Esto puede tomar varios minutos...)" -ForegroundColor Yellow

flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "   APK compilado exitosamente" -ForegroundColor Green
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    $apkSize = (Get-Item $apkPath).Length / 1MB
    Write-Host "   Tamano: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Yellow
}
else {
    Write-Host "   ERROR al compilar APK" -ForegroundColor Red
    exit 1
}

# 4. Commit y push
Write-Host ""
Write-Host "Subiendo cambios a GitHub..." -ForegroundColor Cyan

git add pubspec.yaml
git commit -m "chore: bump version to $newVersion"
git tag -a "v$newVersion" -m "$Message"
git push origin main --tags

# 5. Crear release en GitHub usando API
if ($SkipRelease) {
    Write-Host "Saltando creación de release en GitHub (Token no configurado)..." -ForegroundColor Yellow
}
else {
    Write-Host ""
    Write-Host "Creando release en GitHub..." -ForegroundColor Cyan

    $releaseBody = @"
# iStella v$newVersion

## Cambios

$Message

## Instalacion

1. Descarga el APK adjunto
2. Permite instalacion de fuentes desconocidas
3. Instala el APK

## Configuracion

- Tipo: $(if ($ForceUpdate) { "FORZADA" } else { "Opcional" })
- Build: $newBuild
"@

    # Crear release
    $releaseData = @{
        tag_name   = "v$newVersion"
        name       = "iStella v$newVersion"
        body       = $releaseBody
        draft      = $false
        prerelease = $false
    } | ConvertTo-Json

    $headers = @{
        "Authorization"        = "Bearer $GitHubToken"
        "Accept"               = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/TecnoNando/iStella/releases" `
            -Method Post `
            -Headers $headers `
            -Body $releaseData `
            -ContentType "application/json"
    
        Write-Host "   Release creado: $($release.html_url)" -ForegroundColor Green
    
        # Subir APK al release
        Write-Host "   Subiendo APK..." -ForegroundColor Cyan
    
        $uploadUrl = $release.upload_url -replace '\{\?name,label\}', "?name=app-release.apk"
    
        $apkBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $apkPath))
    
        $uploadHeaders = @{
            "Authorization" = "Bearer $GitHubToken"
            "Accept"        = "application/vnd.github+json"
            "Content-Type"  = "application/vnd.android.package-archive"
        }
    
        $asset = Invoke-RestMethod -Uri $uploadUrl `
            -Method Post `
            -Headers $uploadHeaders `
            -Body $apkBytes
    
        $apkUrl = $asset.browser_download_url
        Write-Host "   APK subido: $apkUrl" -ForegroundColor Green
    }
    catch {
        Write-Host "   ERROR creando release: $_" -ForegroundColor Red
        Write-Host "   Verifica tu token de GitHub" -ForegroundColor Yellow
        exit 1
    }
}

# 6. Actualizar Firebase Remote Config
Write-Host ""
Write-Host "Actualizando Firebase Remote Config..." -ForegroundColor Cyan

$remoteConfigJson = @{
    parameters = @{
        latest_version = @{
            defaultValue = @{ value = $newVersion }
            description  = "Ultima version disponible"
        }
        min_version    = @{
            defaultValue = @{ value = $(if ($ForceUpdate) { $newVersion } else { $currentVersion }) }
            description  = "Version minima requerida"
        }
        force_update   = @{
            defaultValue = @{ value = $ForceUpdate.ToString().ToLower() }
            description  = "Si la actualizacion es obligatoria"
        }
        update_url     = @{
            defaultValue = @{ value = $apkUrl }
            description  = "URL de descarga del APK"
        }
        update_message = @{
            defaultValue = @{ value = $Message }
            description  = "Mensaje de actualizacion"
        }
    }
} | ConvertTo-Json -Depth 10

$configPath = "remote-config.json"
Set-Content -Path $configPath -Value $remoteConfigJson

Write-Host "   Configuracion guardada en: $configPath" -ForegroundColor Yellow

# Desplegar usando firebase deploy (que lee remoteconfig de firebase.json)
Write-Host "   Desplegando a Firebase..." -ForegroundColor Cyan
firebase deploy --only remoteconfig

if ($LASTEXITCODE -eq 0) {
    Write-Host "   Remote Config actualizado exitosamente" -ForegroundColor Green
}
else {
    Write-Host "   ERROR actualizando Remote Config" -ForegroundColor Yellow
    Write-Host "   Intenta correr: firebase deploy --only remoteconfig" -ForegroundColor Yellow
}

# Resumen
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DESPLIEGUE COMPLETADO" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Version: $newVersionFull" -ForegroundColor Green
Write-Host "GitHub: https://github.com/TecnoNando/iStella/releases/tag/v$newVersion" -ForegroundColor Yellow
Write-Host "APK URL: $apkUrl" -ForegroundColor Yellow
Write-Host ""
Write-Host "Importa remote-config.json en Firebase Console" -ForegroundColor Cyan
Write-Host ""
Write-Host "Los usuarios veran la actualizacion al abrir la app!" -ForegroundColor Green
Write-Host ""
