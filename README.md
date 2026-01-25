# Actividad: Despliegue Multi-contenedor con Docker Compose (PHP-FPM + Nginx + MySQL)

## 📋 Objetivos

En esta actividad aprenderás a:

1. ✅ Crear un Dockerfile optimizado para PHP-FPM
2. ✅ Configurar Nginx como reverse proxy
3. ✅ Orquestar múltiples contenedores con Docker Compose
4. ✅ Conectar PHP-FPM con una base de datos MySQL
5. ✅ Implementar volúmenes y redes Docker
6. ✅ Desplegar una aplicación completa localmente

## 📦 Stack

- **PHP-FPM 8.2** (aplicación backend)
- **Nginx** (servidor web + reverse proxy)
- **MySQL 8** (base de datos)
- **Docker Compose** (orquestación)

## ⏱️ Duración estimada

**2-3 horas**, dependiendo de tu experiencia previa con Docker y PHP.

## 🎯 Paso 0: Requisitos previos

Asegúrate de tener instalado:

```bash
# Verificar Docker
docker --version
# Output: Docker version 20.10+

# Verificar Docker Compose
docker compose version
# Output: Docker Compose version v2.0+
```

Si no los tienes, instala [Docker Desktop](https://www.docker.com/products/docker-desktop) en Windows/Mac o sigue las instrucciones en [Docker Engine](https://docs.docker.com/engine/install/) para Linux.

Para esta práctica, podemos usar nuestra máquina virtual "Ubuntu-Docker".

## Paso 1: Estructura del proyecto

Crea la siguiente estructura de directorios:

```plaintext
php-deployment/
├── app/
│   ├── index.php          # Página principal
│   ├── api.php            # API REST
│   └── config/
│       └── database.php   # Configuración BD
├── nginx/
│   └── nginx.conf         # Configuración Nginx
├── docker/
│   └── Dockerfile         # Dockerfile PHP-FPM
├── docker-compose.yml     # Orquestación
├── .env.example           # Variables de entorno (ejemplo)
└── .dockerignore          # Archivos a ignorar en build
```

```bash
mkdir -p php-deployment/{app/config,nginx,docker}
cd php-deployment
```

## Paso 2: Crear la aplicación PHP

### 2.1 Archivo: `app/config/database.php`

```php
<?php
// app/config/database.php

class Database {
    private $host = $_ENV['DB_HOST'] ?? 'localhost';
    private $db = $_ENV['DB_DATABASE'] ?? 'todoapp';
    private $user = $_ENV['DB_USER'] ?? 'root';
    private $pass = $_ENV['DB_PASSWORD'] ?? 'root';
    private $pdo;

    public function connect() {
        try {
            $this->pdo = new PDO(
                "mysql:host={$this->host};dbname={$this->db}",
                $this->user,
                $this->pass,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );
            return $this->pdo;
        } catch (PDOException $e) {
            die("Error de conexión: " . $e->getMessage());
        }
    }
}
?>
```

### 2.2 Archivo: `app/index.php`

```php
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TODO App</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; }
        .container { max-width: 800px; margin: 40px auto; padding: 0 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .content { background: white; padding: 20px; border-radius: 0 0 8px 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { padding: 15px; margin: 20px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .task-list { margin: 20px 0; }
        .task-item { padding: 12px; margin: 10px 0; background: #f9f9f9; border-left: 4px solid #007bff; border-radius: 4px; }
        .form-group { margin: 15px 0; }
        input[type="text"] { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
        button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
        button:hover { background: #0056b3; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📝 TODO App</h1>
            <p>Aplicación multi-contenedor con Docker</p>
        </div>
        <div class="content">
            <?php
            // Verificar conexión a BD
            require_once 'config/database.php';
            
            $db = new Database();
            try {
                $pdo = $db->connect();
                
                // Crear tabla si no existe
                $pdo->exec("CREATE TABLE IF NOT EXISTS todos (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(255) NOT NULL,
                    completed BOOLEAN DEFAULT FALSE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )");
                
                echo '<div class="status success">✅ Conexión a MySQL correcta</div>';
                
                // Obtener tareas
                $stmt = $pdo->query("SELECT * FROM todos ORDER BY created_at DESC");
                $todos = $stmt->fetchAll();
                
                echo '<h2>Tareas (' . count($todos) . ')</h2>';
                
                if (!empty($todos)) {
                    echo '<div class="task-list">';
                    foreach ($todos as $todo) {
                        $checked = $todo['completed'] ? '✓' : '○';
                        echo '<div class="task-item">' . $checked . ' ' . htmlspecialchars($todo['title']) . '</div>';
                    }
                    echo '</div>';
                }
                
            } catch (Exception $e) {
                echo '<div class="status error">❌ Error de conexión: ' . $e->getMessage() . '</div>';
            }
            
            // Información del entorno
            echo '<hr style="margin: 30px 0;">';
            echo '<h3>🔧 Información del sistema</h3>';
            echo '<ul style="line-height: 1.8;">';
            echo '<li><strong>PHP Version:</strong> ' . phpversion() . '</li>';
            echo '<li><strong>Server:</strong> ' . $_SERVER['SERVER_SOFTWARE'] . '</li>';
            echo '<li><strong>Hostname:</strong> ' . gethostname() . '</li>';
            echo '<li><strong>Directorio:</strong> ' . __DIR__ . '</li>';
            echo '<li><strong>DB Host:</strong> ' . ($_ENV['DB_HOST'] ?? 'no configurado') . '</li>';
            echo '</ul>';
            
            // API info
            echo '<hr style="margin: 30px 0;">';
            echo '<h3>📡 API disponible</h3>';
            echo '<p>Prueba la API en: <code>http://localhost/api.php?action=list</code></p>';
            ?>
        </div>
    </div>
</body>
</html>
```

### 2.3 Archivo: `app/api.php`

```php
<?php
// app/api.php - API REST simple

header('Content-Type: application/json');

require_once 'config/database.php';

$db = new Database();
$pdo = $db->connect();

$action = $_GET['action'] ?? 'list';

try {
    switch ($action) {
        case 'list':
            $stmt = $pdo->query("SELECT * FROM todos ORDER BY created_at DESC");
            echo json_encode(['success' => true, 'data' => $stmt->fetchAll()]);
            break;
            
        case 'add':
            $title = $_POST['title'] ?? null;
            if (!$title) {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'Título requerido']);
                break;
            }
            $stmt = $pdo->prepare("INSERT INTO todos (title) VALUES (?)");
            $stmt->execute([$title]);
            echo json_encode(['success' => true, 'id' => $pdo->lastInsertId()]);
            break;
            
        case 'toggle':
            $id = $_POST['id'] ?? null;
            if (!$id) {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'ID requerido']);
                break;
            }
            $stmt = $pdo->prepare("UPDATE todos SET completed = NOT completed WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
            break;
            
        case 'delete':
            $id = $_POST['id'] ?? null;
            if (!$id) {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'ID requerido']);
                break;
            }
            $stmt = $pdo->prepare("DELETE FROM todos WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Acción no válida']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
```

## Paso 3: Dockerfile para PHP-FPM

Crea el archivo `docker/Dockerfile`:

```dockerfile
# ============================================
# Stage 1: Builder (Composer)
# ============================================
FROM composer:2 AS builder

WORKDIR /app

# Para este proyecto sencillo, podríamos tener un composer.json
# COPY composer.json composer.lock ./
# RUN composer install --no-dev --optimize-autoloader

# ============================================
# Stage 2: Runtime PHP-FPM
# ============================================
FROM php:8.2-fpm-alpine

# Instalar extensiones MySQL
RUN apk add --no-cache \
    && docker-php-ext-install pdo pdo_mysql

# Crear usuario no-root
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# Configuración PHP optimizada
RUN echo "max_execution_time = 30" > /usr/local/etc/php/conf.d/custom.ini && \
    echo "memory_limit = 128M" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "upload_max_filesize = 20M" >> /usr/local/etc/php/conf.d/custom.ini

WORKDIR /var/www/html

# Copiar código de la aplicación
COPY --chown=appuser:appuser ./app .

# Cambiar a usuario no-root
USER appuser

# Exponer puerto (FPM)
EXPOSE 9000

CMD ["php-fpm"]
```

## Paso 4: Configuración de Nginx

Crea el archivo `nginx/nginx.conf`:

```nginx
# nginx/nginx.conf

upstream php {
    server app:9000;
}

server {
    listen 80;
    server_name _;
    
    root /var/www/html;
    index index.php;
    
    # Logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;
    
    # Gzip compression
    gzip on;
    gzip_min_length 1000;
    gzip_types text/plain text/css application/json;
    
    # Ruta hacia archivos estáticos
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Bloquear acceso a archivos sensibles
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ ^/app/ {
        deny all;
    }
    
    location ~ \.php$ {
        fastcgi_pass php;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        include fastcgi_params;
        
        # Timeouts
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
    }
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
}
```

## Paso 5: Docker Compose

Crea el archivo `docker-compose.yml` en la raíz del proyecto:

```yaml
version: '3.8'

services:
  # ==========================================
  # Servidor Web (Nginx)
  # ==========================================
  nginx:
    image: nginx:1.25-alpine
    container_name: php-deployment-nginx
    ports:
      - "80:80"
    volumes:
      - ./app:/var/www/html:ro
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - nginx_logs:/var/log/nginx
    depends_on:
      - app
    networks:
      - php-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 10s
      timeout: 5s
      retries: 3

  # ==========================================
  # Aplicación (PHP-FPM)
  # ==========================================
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
    container_name: php-deployment-app
    volumes:
      - ./app:/var/www/html
    environment:
      - DB_HOST=db
      - DB_DATABASE=${DB_DATABASE:-todoapp}
      - DB_USER=${DB_USER:-appuser}
      - DB_PASSWORD=${DB_PASSWORD:-apppassword}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - php-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "php-fpm7", "-t"]
      interval: 10s
      timeout: 5s
      retries: 3

  # ==========================================
  # Base de Datos (MySQL)
  # ==========================================
  db:
    image: mysql:8.0
    container_name: php-deployment-db
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD:-rootpassword}
      MYSQL_DATABASE: ${DB_DATABASE:-todoapp}
      MYSQL_USER: ${DB_USER:-appuser}
      MYSQL_PASSWORD: ${DB_PASSWORD:-apppassword}
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - php-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 3

# ==========================================
# Volúmenes
# ==========================================
volumes:
  db_data:
    driver: local
  nginx_logs:
    driver: local

# ==========================================
# Redes
# ==========================================
networks:
  php-network:
    driver: bridge
```

## Paso 6: Archivo de variables de entorno

Crea el archivo `.env.example`:

```bash
# .env.example
# Copia este archivo a .env y ajusta los valores

DB_HOST=db
DB_DATABASE=todoapp
DB_USER=appuser
DB_PASSWORD=apppassword
DB_ROOT_PASSWORD=rootpassword
```

Luego copia para uso local:

```bash
cp .env.example .env
```

## Paso 7: .dockerignore

Crea el archivo `.dockerignore`, que nos permite evitar copiar archivos innecesarios al contexto de construcción:

```plaintext
.git
.github
.gitignore
.env
.env.*
!.env.example
*.md
docker-compose.yml
docker-compose.*.yml
.DS_Store
node_modules
```

## Paso 8: Desplegar y probar

### 8.1 Construir y levantar los contenedores

```bash
# Levanta todos los servicios (construye si es necesario)
docker compose up -d

# O si quieres ver los logs en tiempo real
docker compose up
```

### 8.2 Verificar que todo está corriendo

```bash
# Ver estado de los contenedores
docker compose ps

# Deberías ver:
# NAME                    STATUS
# php-deployment-nginx    Up (healthy)
# php-deployment-app      Up (healthy)
# php-deployment-db       Up (healthy)
```

### 8.3 Verificar logs

```bash
# Logs de todos los servicios
docker compose logs

# Logs de un servicio específico
docker compose logs app
docker compose logs nginx
docker compose logs db
```

## Paso 9: Probar la aplicación

### 9.1 Acceder a la aplicación web

Abre tu navegador y ve a:

```
http://localhost
```

Deberías ver:

- ✅ "Conexión a MySQL correcta"
- ✅ Lista de tareas (vacía inicialmente)
- ✅ Información del sistema (PHP version, hostname, etc.)

### 9.2 Probar la API REST

Desde la terminal o Postman:

```bash
# Obtener lista de tareas
curl http://localhost/api.php?action=list

# Añadir una tarea (desde bash)
curl -X POST http://localhost/api.php?action=add \
  -d "title=Aprender Docker"

# Obtener tareas nuevamente
curl http://localhost/api.php?action=list
```

### 9.3 Verificar base de datos

Desde tu máquina, accede a MySQL:

```bash
# Conectarse a MySQL
docker compose exec db mysql -u appuser -p todoapp

# Dentro de MySQL:
mysql> SELECT * FROM todos;
```

## Paso 10: Comandos útiles

```bash
# Ver logs en vivo
docker compose logs -f

# Entrar en un contenedor (bash)
docker compose exec app bash
docker compose exec db bash
docker compose exec nginx ash

# Reiniciar un servicio
docker compose restart app

# Detener todo
docker compose down

# Detener y eliminar volúmenes (⚠️ borra datos)
docker compose down -v

# Reconstruir sin caché
docker compose build --no-cache

# Ver uso de recursos
docker compose stats
```

## Paso 11: Debugging

### Problema: "Connection refused"

```bash
# Comprobar que los contenedores están corriendo
docker compose ps

# Ver logs del contenedor app
docker compose logs app

# Comprobar conectividad desde app hacia db
docker compose exec app ping db
```

### Problema: "ERROR 1045 (28000): Access denied"

```bash
# Verificar variables de entorno en el contenedor
docker compose exec app env | grep DB_

# Verificar conexión a MySQL
docker compose logs db
```

### Problema: "502 Bad Gateway en Nginx"

```bash
# Ver logs de Nginx
docker compose logs nginx

# Comprobar que PHP-FPM está escuchando
docker compose exec app php-fpm -t

# Verificar que Nginx puede contactar con app
docker compose exec nginx ping app
```

## ✅ Paso 12: Checklist de éxito

- [ ] Los tres contenedores están corriendo (`docker compose ps`)
- [ ] Nginx está accesible en `http://localhost`
- [ ] PHP muestra "Conexión a MySQL correcta"
- [ ] Puedes crear tareas vía API (`curl ... action=add`)
- [ ] Las tareas persisten después de recargar
- [ ] Los logs son accesibles (`docker compose logs`)
- [ ] Puedes entrar en los contenedores (`docker compose exec`)

## 🎓 Conceptos aprendidos

| Concepto | Descripción |
|----------|-------------|
| **Dockerfile multi-stage** | Build más eficiente con múltiples etapas |
| **Usuario no-root** | Seguridad: ejecutar procesos sin permisos de root |
| **Networking Docker** | Contenedores se comunican por nombre de servicio |
| **Volúmenes** | Persistencia de datos entre reinicios |
| **Healthchecks** | Docker verifica que los servicios están sanos |
| **Variables de entorno** | Configuración flexible mediante `.env` |
| **Nginx como reverse proxy** | Enrutamiento entre cliente y PHP-FPM |
| **Docker Compose** | Orquestación multi-contenedor con `docker-compose.yml` |

## Próximos pasos

1. **Mejorar la app:** Añade más endpoints a la API
2. **Persistencia:** Crea dumps SQL para inicializar la BD
3. **CI/CD automatizado:** Ver [CICD_AUTOMATIZADO.md](CICD_AUTOMATIZADO.md) para despliegues automáticos con GitHub Actions
4. **Registry:** Sube la imagen a Docker Hub o GitHub Container Registry
5. **Producción:** Usa `docker-compose.prod.yml` con variables secretas

## Recursos

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
