# Actividades Propuestas con Soluciones

## Actividad 1: Crear archivo init.sql para inicializar BD

### Enunciado

Crea un archivo SQL que inicialice la base de datos con algunas tareas de ejemplo cuando MySQL arranque.

### Solución

**Paso 1:** Crear archivo `init.sql`:

```sql
-- init.sql
CREATE DATABASE IF NOT EXISTS todoapp;
USE todoapp;

CREATE TABLE IF NOT EXISTS todos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar datos de ejemplo
INSERT INTO todos (title, completed) VALUES
('Aprender Docker', FALSE),
('Configurar Nginx', FALSE),
('Conectar PHP-FPM con MySQL', FALSE),
('Hacer la actividad de Docker Compose', TRUE),
('Subir la imagen a un registry', FALSE);
```

**Paso 2:** Actualizar `docker-compose.yml`:

```yaml
db:
  image: mysql:8.0
  volumes:
    - ./init.sql:/docker-entrypoint-initdb.d/init.sql  # ← Añadir esta línea
    - db_data:/var/lib/mysql
```

**Paso 3:** Reiniciar:

```bash
docker compose down -v
docker compose up -d

# Verificar
docker compose exec db mysql -u appuser -p todoapp -e "SELECT * FROM todos;"
```

---

## Actividad 2: Crear dockerfile.prod optimizado para producción

### Enunciado

Crea un Dockerfile alternativo (`docker/Dockerfile.prod`) que esté optimizado para producción con mejor seguridad y rendimiento.

### Solución

**Archivo:** `docker/Dockerfile.prod`

```dockerfile
# ============================================
# Stage 1: Builder (Dependencias)
# ============================================
FROM composer:2 AS composer_builder

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# ============================================
# Stage 2: Runtime (Producción)
# ============================================
FROM php:8.2-fpm-alpine

# Instalar solo extensiones necesarias
RUN apk add --no-cache \
    && docker-php-ext-install pdo pdo_mysql opcache

# Configuración PHP para producción
RUN echo "display_errors = Off" > /usr/local/etc/php/conf.d/prod.ini \
    && echo "log_errors = On" >> /usr/local/etc/php/conf.d/prod.ini \
    && echo "error_log = /proc/self/fd/2" >> /usr/local/etc/php/conf.d/prod.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/prod.ini \
    && echo "max_execution_time = 60" >> /usr/local/etc/php/conf.d/prod.ini \
    && echo "opcache.enable = 1" >> /usr/local/etc/php/conf.d/prod.ini \
    && echo "opcache.memory_consumption = 128" >> /usr/local/etc/php/conf.d/prod.ini \
    && echo "opcache.max_accelerated_files = 10000" >> /usr/local/etc/php/conf.d/prod.ini

# Crear usuario no-root
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

WORKDIR /var/www/html

# Copiar código
COPY --from=composer_builder /app/vendor ./vendor
COPY --chown=appuser:appuser ./app .

# Cambiar permisos
RUN chmod -R 755 . && \
    chmod -R 775 /var/www/html

USER appuser

EXPOSE 9000

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD php-fpm-healthcheck || exit 1

CMD ["php-fpm"]
```

**Uso:**

```bash
docker build -f docker/Dockerfile.prod -t myapp:prod .
docker push myapp:prod
```

---

## Actividad 3: Crear docker-compose.prod.yml

### Enunciado

Crea un archivo `docker-compose.prod.yml` optimizado para producción con las mejores prácticas.

### Solución

**Archivo:** `docker-compose.prod.yml`

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:1.25-alpine
    container_name: myapp-nginx-prod
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./app:/var/www/html:ro
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro
      - nginx_logs:/var/log/nginx
    depends_on:
      - app
    environment:
      NGINX_HOST: ${NGINX_HOST:-example.com}
      NGINX_PORT: 80
    networks:
      - app-network
    restart: always  # ← always en producción
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health.php"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  app:
    image: ${REGISTRY:-ghcr.io}/myapp:${APP_VERSION:-latest}
    container_name: myapp-app-prod
    volumes:
      - ./app:/var/www/html:ro
      - app_cache:/var/www/html/cache
    environment:
      APP_ENV: production
      DB_HOST: db
      DB_DATABASE: ${DB_DATABASE}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      REDIS_HOST: ${REDIS_HOST:-redis}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app-network
    restart: always
    healthcheck:
      test: ["CMD", "php", "-r", "exit(0);"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  db:
    image: mysql:8.0
    container_name: myapp-db-prod
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    restart: always
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  db_data:
    driver: local
  nginx_logs:
    driver: local
  app_cache:
    driver: local

networks:
  app-network:
    driver: bridge
```

**Desplegar en producción:**

```bash
# Copiar variables de entorno
cp .env.prod.example .env.prod

# Levantar
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Verificar
docker compose -f docker-compose.prod.yml ps
```

---

## Actividad 4: Implementar .htaccess alternativo

### Enunciado

Algunos servidores prefieren usar `.htaccess` en lugar de Nginx. Crea un `.htaccess` que funcione con Apache equivalente a la configuración de Nginx.

### Solución

**Archivo:** `app/.htaccess`

```apache
# .htaccess

<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    
    # Permitir acceso a archivos y directorios reales
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    
    # Redirigir todas las peticiones a index.php
    RewriteRule ^(.*)$ index.php?$1 [QSA,L]
</IfModule>

# Proteger archivos sensibles
<FilesMatch "^\.env">
    Deny from all
</FilesMatch>

<FilesMatch "\.php$">
    Allow from all
</FilesMatch>

# Gzip compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
</IfModule>

# Cache headers
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpeg "access plus 30 days"
    ExpiresByType image/gif "access plus 30 days"
    ExpiresByType image/png "access plus 30 days"
    ExpiresByType text/css "access plus 7 days"
    ExpiresByType text/javascript "access plus 7 days"
</IfModule>
```

---

## Actividad 5: Crear script de backup automático

### Enunciado

Crea un script que realice backup automático de la base de datos MySQL diariamente.

### Solución

**Archivo:** `scripts/backup.sh`

```bash
#!/bin/bash
# Script de backup automático

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/todoapp_$DATE.sql"

mkdir -p $BACKUP_DIR

echo "Iniciando backup..."

# Dump de la base de datos
docker compose exec -T db mysqldump \
    -u appuser \
    -p${DB_PASSWORD:-apppassword} \
    todoapp > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ Backup completado: $BACKUP_FILE"
    
    # Comprimir
    gzip $BACKUP_FILE
    echo "✅ Comprimido: $BACKUP_FILE.gz"
    
    # Mantener solo los últimos 7 backups
    ls -t $BACKUP_DIR/todoapp_*.sql.gz | tail -n +8 | xargs rm -f
    echo "✅ Backups antiguos limpiados"
else
    echo "❌ Error durante el backup"
    exit 1
fi
```

**Configurar en cron (Linux/macOS):**

```bash
# Ejecutar diariamente a las 2 AM
0 2 * * * cd /path/to/php-deployment && bash scripts/backup.sh

# Ver cron jobs
crontab -l
```

**Restaurar desde backup:**

```bash
# Descomprimir
gunzip backups/todoapp_20240101_020000.sql.gz

# Restaurar
docker compose exec -T db mysql -u appuser -p${DB_PASSWORD} todoapp < backups/todoapp_20240101_020000.sql
```

---

## Actividad 6: Integración con GitHub Actions

### Enunciado

Crea un workflow que automáticamente construya y publique la imagen Docker cuando hagas push a main.

### Solución

**Archivo:** `.github/workflows/build-and-push.yml`

```yaml
name: Build and Push Docker Image

on:
  push:
    branches:
      - main
    paths:
      - 'app/**'
      - 'docker/**'
      - 'docker-compose.yml'
      - '.github/workflows/build-and-push.yml'

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/myapp

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./docker/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

      - name: Image digest
        run: echo ${{ steps.docker_build.outputs.digest }}
```

**Configurar secretos en GitHub:**
1. Ir a Settings → Secrets and variables → Actions
2. Los secretos se generan automáticamente (`GITHUB_TOKEN`)

---

## Actividad 7: Crear prueba de carga con Apache Bench

### Enunciado

Escribe un script que realice pruebas de carga a la aplicación.

### Solución

**Archivo:** `tests/load-test.sh`

```bash
#!/bin/bash
# Script de pruebas de carga

HOST="http://localhost"
CONCURRENT=10
REQUESTS=1000

echo "======================================"
echo "Pruebas de carga - ApacheBench"
echo "======================================"
echo ""

# Comprobar que ApacheBench está instalado
if ! command -v ab &> /dev/null; then
    echo "❌ Apache Bench no está instalado"
    echo "Instala con: sudo apt-get install apache2-utils"
    exit 1
fi

# Pruebas
echo "Prueba 1: Página principal"
ab -n $REQUESTS -c $CONCURRENT "$HOST/" | grep -E "Requests per second:|Time per request:|Failed requests:"

echo ""
echo "Prueba 2: API List"
ab -n $REQUESTS -c $CONCURRENT "$HOST/api.php?action=list" | grep -E "Requests per second:|Time per request:|Failed requests:"

echo ""
echo "Prueba 3: Health check"
ab -n $REQUESTS -c $CONCURRENT "$HOST/health.php" | grep -E "Requests per second:|Time per request:|Failed requests:"

echo ""
echo "======================================"
echo "Pruebas completadas"
echo "======================================"
```

**Ejecutar:**

```bash
bash tests/load-test.sh
```

---

## Actividad 8: Añadir validación de entrada

### Enunciado

Mejora la seguridad de `app/api.php` añadiendo validación de entrada y protección contra inyección SQL.

### Solución

**Archivo mejorado:** `app/api.php`

```php
<?php
// app/api.php - Versión segura

header('Content-Type: application/json');

require_once 'config/database.php';

// Función de validación
function validate_input($input, $type = 'string') {
    if ($type === 'string') {
        return trim(htmlspecialchars($input, ENT_QUOTES, 'UTF-8'));
    } elseif ($type === 'integer') {
        return filter_var($input, FILTER_VALIDATE_INT);
    }
    return null;
}

// Función de respuesta JSON
function send_response($success, $data = null, $error = null, $code = 200) {
    http_response_code($code);
    echo json_encode([
        'success' => $success,
        'data' => $data,
        'error' => $error,
        'timestamp' => date('c')
    ]);
    exit();
}

try {
    $db = new Database();
    $pdo = $db->connect();
    
    $action = validate_input($_GET['action'] ?? '', 'string');
    
    if (!in_array($action, ['list', 'add', 'toggle', 'delete'])) {
        send_response(false, null, 'Acción no válida', 400);
    }
    
    switch ($action) {
        case 'list':
            $stmt = $pdo->query("SELECT * FROM todos ORDER BY created_at DESC");
            send_response(true, $stmt->fetchAll());
            break;
            
        case 'add':
            $title = validate_input($_POST['title'] ?? '', 'string');
            
            if (empty($title) || strlen($title) > 255) {
                send_response(false, null, 'Título inválido', 400);
            }
            
            $stmt = $pdo->prepare("INSERT INTO todos (title) VALUES (?)");
            $stmt->execute([$title]);
            
            send_response(true, ['id' => $pdo->lastInsertId()]);
            break;
            
        case 'toggle':
            $id = validate_input($_POST['id'] ?? '', 'integer');
            
            if (!$id || $id <= 0) {
                send_response(false, null, 'ID inválido', 400);
            }
            
            $stmt = $pdo->prepare("UPDATE todos SET completed = NOT completed WHERE id = ?");
            $stmt->execute([$id]);
            
            send_response(true);
            break;
            
        case 'delete':
            $id = validate_input($_POST['id'] ?? '', 'integer');
            
            if (!$id || $id <= 0) {
                send_response(false, null, 'ID inválido', 400);
            }
            
            $stmt = $pdo->prepare("DELETE FROM todos WHERE id = ?");
            $stmt->execute([$id]);
            
            send_response(true);
            break;
    }
    
} catch (PDOException $e) {
    error_log($e->getMessage());
    send_response(false, null, 'Error de base de datos', 500);
} catch (Exception $e) {
    error_log($e->getMessage());
    send_response(false, null, 'Error del servidor', 500);
}
?>
```

---

## Actividad 9: Monitoreo con Prometheus

### Enunciado

Integra Prometheus para monitorear la aplicación y Grafana para visualizar métricas.

### Solución

Ver archivo separado: [EXTENSIONES.md - Sección 9️⃣ Monitoreo con Prometheus](EXTENSIONES.md#monitoreo-con-prometheus)

---

## Actividad 10: Documentación Swagger

### Enunciado

Documenta la API con Swagger/OpenAPI.

### Solución

**Archivo:** `app/swagger.json`

```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "TODO App API",
    "version": "1.0.0"
  },
  "servers": [
    {
      "url": "http://localhost"
    }
  ],
  "paths": {
    "/api.php": {
      "get": {
        "summary": "Listar tareas",
        "parameters": [
          {
            "name": "action",
            "in": "query",
            "required": true,
            "schema": {
              "type": "string",
              "enum": ["list"]
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Lista de tareas"
          }
        }
      },
      "post": {
        "summary": "Crear/actualizar tarea",
        "parameters": [
          {
            "name": "action",
            "in": "query",
            "required": true,
            "schema": {
              "type": "string",
              "enum": ["add", "toggle", "delete"]
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Operación exitosa"
          }
        }
      }
    }
  }
}
```

---

## Rúbrica de evaluación

| Actividad | Puntos |
|-----------|--------|
| Actividad base completada | 5 |
| Al menos 3 actividades bonus | 5 |
| Código documentado | 2 |
| Buen manejo de errores | 2 |
| Pruebas realizadas | 2 |
| Presentación | 4 |
| **Total** | **20** |
