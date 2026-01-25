#!/bin/bash
# Script de instalación y setup para PHP Deployment
# Uso: bash setup.sh

set -e  # Exit on error

# --- Helpers: preflight + troubleshooting (Compose v2) ---
ensure_compose_v2() {
    if docker compose version >/dev/null 2>&1; then
        return 0
    fi
    echo -e "\n\033[0;31m❌ Docker Compose v2 no disponible (comando 'docker compose').\033[0m"
    echo "\nSolución rápida (Ubuntu):"
    echo "  sudo apt update && sudo apt install -y docker-compose-plugin"
    echo "\nVerifica luego con:  docker compose version"
    echo "\nAlternativa temporal: usa 'docker-compose' (v1), pero puede fallar con Docker reciente."
    exit 1
}

on_error() {
    echo -e "\n\033[0;31m❌ Error durante el setup\033[0m"
    echo "Diagnóstico sugerido:"
    echo "  - Ver estado:        docker compose ps"
    echo "  - Logs app:          docker compose logs app"
    echo "  - Logs nginx:        docker compose logs nginx"
    echo "  - Logs db:           docker compose logs db"
    echo "  - Reinicio limpio:   docker compose down --remove-orphans && docker compose up -d --build"
}
trap on_error ERR

echo "======================================"
echo "📦 PHP Deployment - Setup Script"
echo "======================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con color
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar requisitos
info "Verificando requisitos previos..."

if ! command -v docker &> /dev/null; then
    error "Docker no está instalado"
    echo "Instala Docker Desktop desde https://www.docker.com/products/docker-desktop"
    exit 1
fi

success "Docker instalado ($(docker --version))"

info "Verificando Docker Compose v2..."
ensure_compose_v2
success "Docker Compose v2 instalado ($(docker compose version))"

echo ""

# Crear archivo .env
if [ ! -f .env ]; then
    info "Creando archivo .env desde .env.example..."
    cp .env.example .env
    success "Archivo .env creado"
else
    warning "Archivo .env ya existe, usando valores existentes"
fi

echo ""

# Crear estructura de directorios si no existe
info "Verificando estructura de directorios..."
mkdir -p app/config
mkdir -p docker
mkdir -p nginx
success "Estructura de directorios verificada"

echo ""

# Levantar contenedores
info "Levantando contenedores..."
docker compose up -d --build

echo ""

# Esperar a que MySQL esté listo
info "Esperando a que MySQL inicialice (esto puede tardar 30-90 segundos)..."
for i in {1..30}; do
    if docker compose exec -T db mysql -u appuser -p"${DB_PASSWORD:-apppassword}" -e "SELECT 1" todoapp > /dev/null 2>&1; then
        success "MySQL está listo"
        break
    fi
    if [ $i -eq 30 ]; then
        warning "MySQL tardó más de lo esperado, pero continuando..."
    fi
    echo -n "."
    sleep 1
done

echo ""
echo ""

# Mostrar estado
info "Estado de los contenedores:"
docker compose ps

echo ""
echo "======================================"
echo "🎉 Setup completado"
echo "======================================"
echo ""
echo -e "${GREEN}La aplicación está disponible en:${NC}"
echo -e "  🌐 ${BLUE}http://localhost/${NC}"
echo ""
echo -e "${GREEN}Comandos útiles:${NC}"
echo "  Ver logs:        docker compose logs -f"
echo "  Entrar en bash:  docker compose exec app bash"
echo "  Acceder BD:      docker compose exec db mysql -u appuser -p -D todoapp"
echo "  Detener:         docker compose down"
echo "  Limpiar todo:    docker compose down -v"
echo ""
echo -e "${YELLOW}Primeros pasos:${NC}"
echo "  1. Abre http://localhost en tu navegador"
echo "  2. Deberías ver '✅ Conexión a MySQL correcta'"
echo "  3. Prueba la API: curl http://localhost/api.php?action=list"
echo ""
echo -e "${BLUE}Documentación:${NC}"
echo "  - Guía completa:     README.md"
echo "  - Guía rápida:       QUICKSTART.md"
echo "  - Problemas:         TROUBLESHOOTING.md"
echo "  - Extensiones:       EXTENSIONES.md"
echo ""
