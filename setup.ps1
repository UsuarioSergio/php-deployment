# Script de instalación y setup para PHP Deployment (Windows)
# Uso: powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "📦 PHP Deployment - Setup Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Función para imprimir con color
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

# Verificar requisitos
Write-Info "Verificando requisitos previos..."

try {
    $dockerVersion = docker --version
    Write-Success "Docker instalado ($dockerVersion)"
} catch {
    Write-Error-Custom "Docker no está instalado"
    Write-Host "Instala Docker Desktop desde https://www.docker.com/products/docker-desktop"
    exit 1
}

try {
    $composeVersion = docker compose version
    Write-Success "Docker Compose instalado"
} catch {
    Write-Error-Custom "Docker Compose no está instalado"
    exit 1
}

Write-Host ""

# Crear archivo .env
if (!(Test-Path ".env")) {
    Write-Info "Creando archivo .env desde .env.example..."
    Copy-Item -Path ".env.example" -Destination ".env"
    Write-Success "Archivo .env creado"
} else {
    Write-Warning "Archivo .env ya existe, usando valores existentes"
}

Write-Host ""

# Crear estructura de directorios
Write-Info "Verificando estructura de directorios..."
$directories = @(
    "app/config",
    "docker",
    "nginx"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Success "Estructura de directorios verificada"

Write-Host ""

# Levantar contenedores
Write-Info "Levantando contenedores..."
docker compose up -d --build

Write-Host ""

# Esperar a que MySQL esté listo
Write-Info "Esperando a que MySQL inicialice (esto puede tardar 30 segundos)..."
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        docker compose exec -T db cmd /c "mysql -u appuser -papppassword -D todoapp -e 'SELECT 1'" 2>$null | Out-Null
        $ready = $true
        Write-Success "MySQL está listo"
        break
    } catch {
        if ($i -eq 30) {
            Write-Warning "MySQL tardó más de lo esperado, pero continuando..."
        }
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 1
    }
}

Write-Host ""
Write-Host ""

# Mostrar estado
Write-Info "Estado de los contenedores:"
docker compose ps

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "🎉 Setup completado" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "La aplicación está disponible en:" -ForegroundColor Green
Write-Host "  🌐 http://localhost/" -ForegroundColor Cyan
Write-Host ""

Write-Host "Comandos útiles:" -ForegroundColor Green
Write-Host "  Ver logs:        docker compose logs -f"
Write-Host "  Entrar en bash:  docker compose exec app bash"
Write-Host "  Acceder BD:      docker compose exec db mysql -u appuser -p -D todoapp"
Write-Host "  Detener:         docker compose down"
Write-Host "  Limpiar todo:    docker compose down -v"
Write-Host ""

Write-Host "Primeros pasos:" -ForegroundColor Yellow
Write-Host "  1. Abre http://localhost en tu navegador"
Write-Host "  2. Deberías ver '✅ Conexión a MySQL correcta'"
Write-Host "  3. Prueba la API: curl http://localhost/api.php?action=list"
Write-Host ""

Write-Host "Documentación:" -ForegroundColor Cyan
Write-Host "  - Guía completa:     README.md"
Write-Host "  - Guía rápida:       QUICKSTART.md"
Write-Host "  - Problemas:         TROUBLESHOOTING.md"
Write-Host "  - Extensiones:       EXTENSIONES.md"
Write-Host ""
