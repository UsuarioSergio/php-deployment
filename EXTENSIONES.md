# Actividades Complementarias - PHP Deployment

## Extensiones propuestas para esta actividad

Una vez completada la actividad base, aquí hay varias extensiones que puedes implementar:

---

## 1️⃣ Mejorar la UI de la aplicación

### Tarea: Añadir formulario para crear tareas

Modifica `app/index.php` para añadir un formulario:

```html
<h3>Crear nueva tarea</h3>
<form method="POST" action="/api.php?action=add">
    <div class="form-group">
        <input type="text" name="title" placeholder="Escribe una tarea..." required>
        <button type="submit">Añadir</button>
    </div>
</form>
```

**Puntos clave:**
- Validación HTML5
- Redirección después de crear
- Mostrar mensaje de éxito/error

---

## 2️⃣ Usar Composer para dependencias

### Tarea: Integrar un framework como Slim o Laravel

**Paso 1:** Crear `composer.json`:

```json
{
    "require": {
        "slim/slim": "^4.0",
        "slim/psr7": "^1.6"
    }
}
```

**Paso 2:** Descomenta el stage de Composer en el Dockerfile:

```dockerfile
FROM composer:2 AS builder
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# ... en el stage de runtime:
COPY --from=builder /app/vendor ./vendor
```

**Paso 3:** Refactoriza la API con Slim:

```php
<?php
require 'vendor/autoload.php';
$app = new \Slim\Slim\Slim();

$app->get('/api/todos', function ($request, $response) {
    // Lógica aquí
});

$app->run();
?>
```

---

## 3️⃣ Añadir Redis para caché

### Tarea: Implementar caché de sesiones

**Paso 1:** Actualizar `docker-compose.yml`:

```yaml
  redis:
    image: redis:7-alpine
    container_name: php-deployment-redis
    networks:
      - php-network
    restart: unless-stopped
```

**Paso 2:** Instalar extensión Redis en Dockerfile:

```dockerfile
RUN apk add --no-cache build-base \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del build-base
```

**Paso 3:** Usar Redis en la aplicación:

```php
<?php
$redis = new Redis();
$redis->connect('redis', 6379);
$redis->set('user:123', json_encode($userData), 3600);
?>
```

---

## 4️⃣ Implementar HTTPS/SSL

### Tarea: Añadir certificados SSL autofirmados

**Paso 1:** Generar certificados:

```bash
mkdir -p nginx/certs
openssl req -x509 -newkey rsa:4096 -nodes \
  -out nginx/certs/cert.pem \
  -keyout nginx/certs/key.pem \
  -days 365
```

**Paso 2:** Actualizar `nginx/nginx.conf`:

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    
    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    
    # Redirigir HTTP a HTTPS
    if ($scheme = http) {
        return 301 https://$server_name$request_uri;
    }
    
    # ... resto de configuración
}
```

**Paso 3:** Actualizar puertos en `docker-compose.yml`:

```yaml
nginx:
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx/certs:/etc/nginx/certs:ro
```

---

## 5️⃣ Automatizar con GitHub Actions

### Tarea: Crear workflow de CI/CD

**Paso 1:** Crear `.github/workflows/test.yml`:

```yaml
name: Test and Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

    steps:
      - uses: actions/checkout@v3
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: pdo_mysql
      
      - name: Install dependencies
        run: composer install
      
      - name: Run tests
        run: vendor/bin/phpunit
      
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} -f docker/Dockerfile .
      
      - name: Push to registry
        run: |
          docker login -u ${{ secrets.REGISTRY_USER }} -p ${{ secrets.REGISTRY_PASSWORD }}
          docker tag myapp:${{ github.sha }} myrepo/myapp:latest
          docker push myrepo/myapp:latest
```

---

## 6️⃣ Implementar Health Checks

### Tarea: Crear endpoint de salud personalizado

**Paso 1:** Crear `app/health.php`:

```php
<?php
header('Content-Type: application/json');

$status = [
    'status' => 'up',
    'timestamp' => date('c'),
    'services' => []
];

// Comprobar base de datos
try {
    require 'config/database.php';
    $db = new Database();
    $pdo = $db->connect();
    $pdo->query("SELECT 1");
    $status['services']['database'] = 'ok';
} catch (Exception $e) {
    $status['status'] = 'down';
    $status['services']['database'] = 'error: ' . $e->getMessage();
}

// Comprobar PHP
$status['services']['php'] = 'ok';

http_response_code($status['status'] === 'up' ? 200 : 503);
echo json_encode($status, JSON_PRETTY_PRINT);
?>
```

**Paso 2:** Usar en Docker Compose:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health.php"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

---

## 7️⃣ Logging centralizado

### Tarea: Enviar logs a un servicio centralizado

**Opción 1: Usar Filebeat y ELK Stack**

```yaml
# docker-compose.yml
  filebeat:
    image: docker.elastic.co/beats/filebeat:8.0.0
    volumes:
      - ./filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - nginx_logs:/var/log/nginx:ro
    networks:
      - php-network
```

**Opción 2: Usar Syslog**

```yaml
logging:
  driver: syslog
  options:
    syslog-address: "udp://localhost:514"
```

---

## 8️⃣ Testing con PHPUnit

### Tarea: Escribir tests para la aplicación

**Paso 1:** Instalar PHPUnit:

```bash
docker compose exec app composer require --dev phpunit/phpunit
```

**Paso 2:** Crear `app/tests/DatabaseTest.php`:

```php
<?php
namespace App\Tests;

use PHPUnit\Framework\TestCase;
use Database;

class DatabaseTest extends TestCase {
    private $pdo;
    
    protected function setUp(): void {
        require_once __DIR__ . '/../config/database.php';
        $db = new Database();
        $this->pdo = $db->connect();
    }
    
    public function testDatabaseConnection(): void {
        $result = $this->pdo->query("SELECT 1");
        $this->assertNotFalse($result);
    }
    
    public function testInsertTodo(): void {
        $stmt = $this->pdo->prepare("INSERT INTO todos (title) VALUES (?)");
        $stmt->execute(['Test Todo']);
        $this->assertEquals(1, $stmt->rowCount());
    }
}
?>
```

**Paso 3:** Ejecutar tests:

```bash
docker compose exec app ./vendor/bin/phpunit
```

---

## 9️⃣ Monitoreo con Prometheus

### Tarea: Recopilar métricas

**Paso 1:** Instalar biblioteca Prometheus:

```bash
docker compose exec app composer require prometheus/client
```

**Paso 2:** Crear endpoint de métricas en `app/metrics.php`:

```php
<?php
require 'vendor/autoload.php';

use Prometheus\CollectorRegistry;
use Prometheus\Storage\InMemory;
use Prometheus\Renderer\RenderTextFormat;

$registry = new CollectorRegistry(new InMemory());

$counter = $registry->registerCounter(
    'app',
    'requests_total',
    'Total requests'
);
$counter->inc();

$gauge = $registry->registerGauge(
    'app',
    'active_tasks',
    'Active todos'
);

// Obtener número de tareas
require 'config/database.php';
$db = new Database();
$pdo = $db->connect();
$count = $pdo->query("SELECT COUNT(*) FROM todos")->fetchColumn();
$gauge->set($count);

$renderer = new RenderTextFormat();
header('Content-Type: ' . RenderTextFormat::MIME_TYPE);
echo $renderer->render($registry->getMetricFamilySamples());
?>
```

**Paso 3:** Añadir Prometheus a Docker Compose:

```yaml
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
  networks:
    - php-network
```

---

## 🔟 Multi-arquitectura

### Tarea: Compilar para ARM64 y x86

**Paso 1:** Usar buildx:

```bash
# Habilitar buildx
docker buildx create --name mybuilder
docker buildx use mybuilder

# Compilar para múltiples arquitecturas
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myrepo/myapp:latest \
  -f docker/Dockerfile \
  --push .
```

**Paso 2:** Verificar imagen multi-arquitectura:

```bash
docker inspect myrepo/myapp:latest | grep -A 5 "Architecture"
```

---

## 📊 Rúbrica de Evaluación (Opcional)

| Criterio | Puntos |
|----------|--------|
| Actividad base completada | 4 |
| Extensión 1 implementada | 2 |
| Extensión 2 implementada | 2 |
| Extensión 3 implementada | 2 |
| Código documentado | 2 |
| Buen manejo de errores | 2 |
| Seguridad implementada | 2 |
| Presentación y explicación | 2 |
| **Total** | **20** |

---

## 🎯 Entregables propuestos

### Opción 1: Repositorio GitHub

```
tu-repo/
├── .github/workflows/
│   └── test-and-deploy.yml
├── app/
│   ├── config/
│   ├── tests/
│   ├── index.php
│   └── api.php
├── docker/
│   └── Dockerfile
├── nginx/
│   └── nginx.conf
├── docker-compose.yml
├── composer.json
└── README.md
```

### Opción 2: Documentación

- Memoria explicando cada componente
- Capturas de pantalla del funcionamiento
- Troubleshooting realizado
- Pruebas ejecutadas
- Mejoras implementadas

---

## 🔗 Referencias útiles

- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Compose Service Dependencies](https://docs.docker.com/compose/compose-file/05-services/#depends_on)
- [PHP-FPM Tuning](https://blog.sergeynovikov.com/optimizing-php-fpm/)
- [Nginx Reverse Proxy](https://nginx.org/en/docs/http/ngx_http_upstream_module.html)
- [MySQL Best Practices](https://dev.mysql.com/doc/mysql-installation-excerpt/8.0/en/)
