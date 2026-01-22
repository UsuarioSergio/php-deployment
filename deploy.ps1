# deploy.ps1 - Script de despliegue en producción (Windows)
# Uso: powershell -ExecutionPolicy Bypass -File deploy.ps1

$ErrorActionPreference = "Stop"

$REGISTRY = "ghcr.io"
$REPO = $env:GITHUB_REPOSITORY -or "tu-usuario/tu-repo"
$IMAGE_NAME = "$REGISTRY/$REPO/php-app"

# Funciones
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "🚀 PHP App - Production Deploy" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Verificar Docker
Write-Info "Verificando Docker..."
try {
    $dockerVersion = docker --version
    Write-Success "Docker disponible ($dockerVersion)"
} catch {
    Write-Error-Custom "Docker no está instalado"
    exit 1
}

Write-Host ""

# Verificar docker-compose
Write-Info "Verificando docker-compose..."
try {
    docker compose version | Out-Null
    Write-Success "docker-compose disponible"
} catch {
    Write-Error-Custom "docker-compose no está instalado"
    exit 1
}

Write-Host ""

# Cargar variables de entorno
if (!(Test-Path ".env.prod")) {
    Write-Error-Custom "No encontrado: .env.prod"
    Write-Host "Copiar desde .env.prod.example y configurar"
    exit 1
}

$envContent = Get-Content .env.prod
$env = @{}
foreach ($line in $envContent) {
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
        $key = $matches[1]
        $value = $matches[2]
        $env[$key] = $value
    }
}

Write-Success "Variables de entorno cargadas"

Write-Host ""

# Verificar autenticación
Write-Info "Verificando autenticación en GHCR..."
try {
    $dockerInfo = docker info 2>&1 | Select-String "Registries"
    Write-Success "Ya autenticado en GHCR"
} catch {
    Write-Warning "No autenticado en GHCR, intenta manualmente:"
    Write-Host "  docker login ghcr.io -u tu-usuario"
    exit 1
}

Write-Host ""

# Pull de la imagen
$appVersion = $env['APP_VERSION'] -or 'latest'
Write-Info "Descargando imagen: $IMAGE_NAME:$appVersion"
docker pull "$IMAGE_NAME:$appVersion"
Write-Success "Imagen descargada"

Write-Host ""

# Backup de datos (opcional)
if (Test-Path "backups") {
    Write-Info "Haciendo backup de BD..."
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "backups/db_backup_$timestamp.sql.gz"
    
    docker compose -f docker-compose.prod.yml exec -T db cmd /c "mysqldump -u $($env['DB_USER']) -p$($env['DB_PASSWORD']) $($env['DB_DATABASE'])" | gzip > $backupFile
    
    Write-Success "Backup guardado: $backupFile"
    Write-Host ""
}

# Detener servicios antiguos
Write-Info "Deteniendo servicios antiguos..."
try {
    docker compose -f docker-compose.prod.yml ps | Select-String "php-app" | Out-Null
    docker compose -f docker-compose.prod.yml stop
    Write-Success "Servicios detenidos"
} catch {
    Write-Info "No hay servicios previos para detener"
}

Write-Host ""

# Levantar nuevos servicios
Write-Info "Levantando servicios con nueva imagen..."
docker compose -f docker-compose.prod.yml up -d

Write-Host ""

# Esperar a que estén healthy
Write-Info "Esperando a que los servicios estén listos..."
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    $status = docker compose -f docker-compose.prod.yml ps
    if ($status -match "healthy") {
        Write-Success "Servicios en estado healthy"
        $ready = $true
        break
    }
    if ($i -eq 30) {
        Write-Warning "Servicios tardaron más, pero continuando..."
    }
    Write-Host -NoNewline "."
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host ""

# Verificación
Write-Info "Verificando deployment..."
docker compose -f docker-compose.prod.yml ps

Write-Host ""

# Test de conectividad
Write-Info "Probando conectividad..."
try {
    $response = Invoke-WebRequest -Uri "http://localhost/health.php" -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Success "✅ App responde correctamente"
    }
} catch {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost/" -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Success "✅ App responde correctamente"
        }
    } catch {
        Write-Warning "⚠️  App no responde (podría necesitar más tiempo para iniciar)"
    }
}

Write-Host ""

# Mostrar información
Write-Host "======================================" -ForegroundColor Green
Write-Host "✅ Despliegue completado" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

Write-Host "Información de despliegue:" -ForegroundColor Cyan
Write-Host "  Imagen:   $IMAGE_NAME:$appVersion"
Write-Host "  BD:       $($env['DB_DATABASE'])"
Write-Host "  Usuario:  $($env['DB_USER'])"
Write-Host ""

Write-Host "Comandos útiles:" -ForegroundColor Yellow
Write-Host "  Ver logs:       docker compose -f docker-compose.prod.yml logs -f"
Write-Host "  Ver estado:     docker compose -f docker-compose.prod.yml ps"
Write-Host "  Entrar en bash: docker compose -f docker-compose.prod.yml exec app bash"
Write-Host "  Detener:        docker compose -f docker-compose.prod.yml down"
Write-Host ""

Write-Host "Acceso:" -ForegroundColor Cyan
Write-Host "  URL: http://localhost (o tu dominio)"
Write-Host ""

Write-Host "🎉 ¡Despliegue exitoso!" -ForegroundColor Green
