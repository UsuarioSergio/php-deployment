#!/bin/bash
# deploy.sh - Script de despliegue en producción
# Uso: bash deploy.sh

set -e

# Opcion 1 : ghcr.io (GitHub Container Registry)
REGISTRY="ghcr.io"
REPO="${GITHUB_REPOSITORY:-danielmartinan/php-deployment}"
IMAGE_NAME="$REGISTRY/$REPO/php-app"

# Opción 2: Docker Hub
# REGISTRY="${REGISTRY:-docker.io}"
# DOCKERHUB_USER="${DOCKERHUB_USER:-$(read -p 'Docker Hub username: ' -r; echo $REPLY)}"
# IMAGE_NAME="$DOCKERHUB_USER/php-app"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

echo "======================================"
echo "🚀 PHP App - Production Deploy"
echo "======================================"
echo ""

# Verificar Docker
info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    error "Docker no está instalado"
    exit 1
fi
success "Docker disponible ($(docker --version))"

echo ""

# Verificar docker-compose
info "Verificando docker-compose..."
if ! command -v docker-compose &> /dev/null; then
    error "docker-compose no está instalado"
    exit 1
fi
success "docker-compose disponible"

echo ""

# Cargar variables de entorno
if [ ! -f .env.prod ]; then
    error "No encontrado: .env.prod"
    echo "Copiar desde .env.prod.example y configurar"
    exit 1
fi

source .env.prod
success "Variables de entorno cargadas"

echo ""

# Verificar autenticación
info "Verificando autenticación en GHCR..."
if ! docker info | grep -q "Registries:"; then
    warning "No autenticado en GHCR, intentando login..."
    read -p "GitHub username: " GH_USER
    read -sp "GitHub token (o password): " GH_TOKEN
    echo ""
    
    echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin
    success "Login exitoso"
else
    success "Ya autenticado en GHCR"
fi

echo ""

# Pull de la imagen
info "Descargando imagen: $IMAGE_NAME:${APP_VERSION:-latest}"
docker pull "$IMAGE_NAME:${APP_VERSION:-latest}"
success "Imagen descargada"

echo ""

# Backup de datos (opcional pero recomendado)
if [ -d "backups" ]; then
    info "Haciendo backup de BD..."
    BACKUP_FILE="backups/db_backup_$(date +%Y%m%d_%H%M%S).sql.gz"
    docker-compose -f docker-compose.prod.yml exec -T db mysqldump \
        -u "$DB_USER" \
        -p"$DB_PASSWORD" \
        "$DB_DATABASE" | gzip > "$BACKUP_FILE"
    success "Backup guardado: $BACKUP_FILE"
    echo ""
fi

# Detener servicios antiguos (si existen)
if docker-compose -f docker-compose.prod.yml ps | grep -q "php-app"; then
    info "Deteniendo servicios antiguos..."
    docker-compose -f docker-compose.prod.yml stop
    success "Servicios detenidos"
    echo ""
fi

# Levantar nuevos servicios
info "Levantando servicios con nueva imagen..."
docker-compose -f docker-compose.prod.yml up -d

echo ""

# Esperar a que estén healthy
info "Esperando a que los servicios estén listos..."
for i in {1..30}; do
    if docker-compose -f docker-compose.prod.yml ps | grep -q "healthy"; then
        success "Servicios en estado healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        warning "Servicios tardaron más, pero continuando..."
    fi
    echo -n "."
    sleep 1
done

echo ""
echo ""

# Verificación
info "Verificando deployment..."
docker-compose -f docker-compose.prod.yml ps

echo ""

# Test de conectividad
info "Probando conectividad..."
if curl -f http://localhost/health.php > /dev/null 2>&1; then
    success "✅ App responde correctamente"
elif curl -f http://localhost/ > /dev/null 2>&1; then
    success "✅ App responde correctamente"
else
    warning "⚠️  App no responde (podría necesitar más tiempo para iniciar)"
fi

echo ""

# Mostrar información
echo "======================================"
echo "✅ Despliegue completado"
echo "======================================"
echo ""
echo "Información de despliegue:"
echo "  Imagen:   $IMAGE_NAME:${APP_VERSION:-latest}"
echo "  BD:       $DB_DATABASE"
echo "  Usuario:  $DB_USER"
echo ""
echo "Comandos útiles:"
echo "  Ver logs:       docker-compose -f docker-compose.prod.yml logs -f"
echo "  Ver estado:     docker-compose -f docker-compose.prod.yml ps"
echo "  Entrar en bash: docker-compose -f docker-compose.prod.yml exec app bash"
echo "  Detener:        docker-compose -f docker-compose.prod.yml down"
echo ""
echo "Acceso:"
echo "  URL: http://localhost (o tu dominio)"
echo ""

# Crear symlink para facilitar próximos deploys
if [ ! -L "deploy" ]; then
    ln -s deploy.sh deploy
    success "Próximas veces puedes ejecutar: ./deploy"
fi

echo "¡Despliegue exitoso!"
