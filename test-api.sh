#!/bin/bash
# test-api.sh - Script de prueba para la API REST de TODO App
# Uso: bash test-api.sh [URL]

set -e

# URL base (por defecto localhost:8083, o argumento)
BASE_URL="${1:-http://localhost:8083}"
API_URL="$BASE_URL/api.php"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Funciones
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# Verificar que curl y jq estén disponibles
if ! command -v curl &> /dev/null; then
    error "curl no está instalado"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    warning "jq no está instalado (salida sin formato)"
    JQ_CMD="cat"
else
    JQ_CMD="jq"
fi

echo "======================================"
echo "🧪 TODO App - API Test Suite"
echo "======================================"
echo "URL Base: $BASE_URL"
echo ""

# Test 1: Verificar conectividad
info "Test 1: Verificando conectividad..."
if curl -f -s "$BASE_URL" > /dev/null 2>&1; then
    success "Servidor accesible"
else
    error "No se puede conectar a $BASE_URL"
    echo "Verifica que el servidor esté corriendo:"
    echo "  docker compose -f docker-compose.prod.yml ps"
    exit 1
fi
echo ""

# Test 2: Listar tareas iniciales
info "Test 2: Listando tareas existentes..."
RESPONSE=$(curl -s "$API_URL?action=list")
echo "$RESPONSE" | $JQ_CMD
INITIAL_COUNT=$(echo "$RESPONSE" | jq -r '.data | length' 2>/dev/null || echo "?")
success "Tareas existentes: $INITIAL_COUNT"
echo ""

# Test 3: Añadir nuevas tareas
info "Test 3: Añadiendo nuevas tareas..."
TASKS=(
    "Verificar deployment"
    "Revisar logs de Nginx"
    "Configurar backup automático"
    "Documentar API"
)

TASK_IDS=()
for task in "${TASKS[@]}"; do
    RESPONSE=$(curl -s -X POST "$API_URL?action=add" -d "title=$task")
    TASK_ID=$(echo "$RESPONSE" | jq -r '.id' 2>/dev/null || echo "")
    
    if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "null" ]; then
        success "Tarea añadida: '$task' (ID: $TASK_ID)"
        TASK_IDS+=("$TASK_ID")
    else
        error "Fallo al añadir: '$task'"
        echo "$RESPONSE" | $JQ_CMD
    fi
done
echo ""

# Test 4: Listar todas las tareas
info "Test 4: Listando todas las tareas..."
RESPONSE=$(curl -s "$API_URL?action=list")
echo "$RESPONSE" | $JQ_CMD
NEW_COUNT=$(echo "$RESPONSE" | jq -r '.data | length' 2>/dev/null || echo "?")
success "Total de tareas: $NEW_COUNT"
echo ""

# Test 5: Marcar tareas como completadas
info "Test 5: Marcando tareas como completadas..."
if [ ${#TASK_IDS[@]} -gt 0 ]; then
    # Marcar las dos primeras como completadas
    for i in 0 1; do
        if [ $i -lt ${#TASK_IDS[@]} ]; then
            ID="${TASK_IDS[$i]}"
            RESPONSE=$(curl -s -X POST "$API_URL?action=toggle" -d "id=$ID")
            if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
                success "Tarea $ID marcada como completada"
            else
                error "Fallo al marcar tarea $ID"
                echo "$RESPONSE" | $JQ_CMD
            fi
        fi
    done
else
    warning "No hay IDs de tareas para marcar"
fi
echo ""

# Test 6: Ver estado actualizado
info "Test 6: Verificando estado actualizado..."
RESPONSE=$(curl -s "$API_URL?action=list")
COMPLETED=$(echo "$RESPONSE" | jq -r '[.data[] | select(.completed == "1" or .completed == true)] | length' 2>/dev/null || echo "?")
PENDING=$(echo "$RESPONSE" | jq -r '[.data[] | select(.completed == "0" or .completed == false)] | length' 2>/dev/null || echo "?")
success "Completadas: $COMPLETED | Pendientes: $PENDING"
echo ""

# Test 7: Eliminar una tarea
info "Test 7: Eliminando una tarea de prueba..."
if [ ${#TASK_IDS[@]} -gt 0 ]; then
    DELETE_ID="${TASK_IDS[-1]}"  # Última tarea añadida
    RESPONSE=$(curl -s -X POST "$API_URL?action=delete" -d "id=$DELETE_ID")
    if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        success "Tarea $DELETE_ID eliminada correctamente"
    else
        error "Fallo al eliminar tarea $DELETE_ID"
        echo "$RESPONSE" | $JQ_CMD
    fi
else
    warning "No hay IDs de tareas para eliminar"
fi
echo ""

# Test 8: Verificación final
info "Test 8: Verificación final..."
RESPONSE=$(curl -s "$API_URL?action=list")
echo "$RESPONSE" | $JQ_CMD
FINAL_COUNT=$(echo "$RESPONSE" | jq -r '.data | length' 2>/dev/null || echo "?")
success "Total final de tareas: $FINAL_COUNT"
echo ""

# Resumen
echo "======================================"
echo "✅ Tests completados"
echo "======================================"
echo ""
echo "Resumen:"
echo "  Tareas iniciales:  $INITIAL_COUNT"
echo "  Tareas añadidas:   ${#TASKS[@]}"
echo "  Tareas finales:    $FINAL_COUNT"
echo "  Completadas:       $COMPLETED"
echo "  Pendientes:        $PENDING"
echo ""
echo "Ver en navegador:"
echo "  $BASE_URL"
echo ""
echo "Comandos útiles:"
echo "  # Listar tareas"
echo "  curl '$API_URL?action=list' | jq"
echo ""
echo "  # Añadir tarea"
echo "  curl -X POST '$API_URL?action=add' -d 'title=Mi tarea'"
echo ""
echo "  # Marcar completada (ID=1)"
echo "  curl -X POST '$API_URL?action=toggle' -d 'id=1'"
echo ""
echo "  # Eliminar (ID=1)"
echo "  curl -X POST '$API_URL?action=delete' -d 'id=1'"
echo ""
