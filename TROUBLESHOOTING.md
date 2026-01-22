# Guía de Troubleshooting - PHP Deployment

## Problemas comunes y soluciones

### 1. Error: "Connection refused" en la aplicación

**Síntomas:**
- Mensaje de error: "Error de conexión: Connection refused"
- `http://localhost` muestra error rojo

**Causas comunes:**
- Los contenedores no están corriendo
- MySQL no ha inicializado correctamente
- Variables de entorno incorrectas

**Soluciones:**

```bash
# 1. Verificar estado de los contenedores
docker compose ps

# Deberías ver 3 contenedores con status "Up (healthy)"
# Si ves "Up (unhealthy)" o "Exited", hay un problema

# 2. Ver logs para identificar el error
docker compose logs app
docker compose logs db

# 3. Si MySQL aún no está listo, espera un poco
docker compose logs db | grep "ready for connections"

# 4. Reiniciar los contenedores
docker compose restart

# 5. Si persiste, destruir y reconstruir
docker compose down -v  # Borra datos
docker compose up -d
```

---

### 2. Error: "ERROR 1045 (28000): Access denied"

**Síntomas:**
- Aplicación muestra: "Error de conexión: SQLSTATE[HY000]"
- Logs muestran "Access denied for user"

**Causas:**
- Credenciales de MySQL incorrectas
- Variables de entorno no sincronizadas

**Soluciones:**

```bash
# 1. Verificar las variables de entorno en el contenedor app
docker compose exec app env | grep DB_

# 2. Comparar con docker-compose.yml y .env
cat .env
cat docker-compose.yml | grep -A 5 "environment:"

# 3. Si están mal, actualizar .env y reiniciar
# Asegúrate de que coincidan:
# - DB_USER en docker-compose.yml (MYSQL_USER en db service)
# - DB_PASSWORD en docker-compose.yml (MYSQL_PASSWORD en db service)

# 4. Destruir la base de datos y empezar de nuevo
docker compose down -v
docker compose up -d
```

---

### 3. Error: "502 Bad Gateway" en Nginx

**Síntomas:**
- Accedes a `http://localhost` pero ves "502 Bad Gateway"

**Causas:**
- PHP-FPM no está escuchando
- Nginx no puede conectar con el contenedor app
- Error en el código PHP

**Soluciones:**

```bash
# 1. Ver logs de Nginx
docker compose logs nginx

# Buscar errores como "connect() failed" o "connection refused"

# 2. Comprobar que PHP-FPM está activo
docker compose exec app ps aux | grep "php-fpm"

# 3. Comprobar la sintaxis de nginx.conf
docker compose exec nginx nginx -t

# 4. Verificar que el contenedor app está corriendo
docker compose ps app

# 5. Comprobar conectividad entre contenedores
docker compose exec nginx ping app
docker compose exec nginx ping db

# 6. Si falla, reconstruir la imagen
docker compose build --no-cache
docker compose up -d
```

---

### 4. Error: "Dockerfile not found"

**Síntomas:**
- Error: "build context cannot contain Dockerfile"

**Causas:**
- Ruta incorrecta al Dockerfile

**Soluciones:**

```bash
# 1. Verificar que el archivo existe
ls -la docker/Dockerfile

# 2. Verificar que docker-compose.yml tiene la ruta correcta
cat docker-compose.yml | grep -A 3 "build:"

# Debería mostrar:
# build:
#   context: .
#   dockerfile: docker/Dockerfile
```

---

### 5. Error: "Port 80 already in use"

**Síntomas:**
- Error: "bind: permission denied" o "Address already in use"

**Causas:**
- Otro servicio usando el puerto 80
- Proceso anterior de Docker aún activo

**Soluciones:**

```bash
# Windows PowerShell
Get-NetTCPConnection -LocalPort 80 | Select ProcessName

# macOS/Linux
lsof -i :80

# Opción 1: Liberar el puerto
# En Windows, busca el proceso con PID y termínalo
taskkill /PID <PID> /F

# Opción 2: Cambiar el puerto en docker-compose.yml
# Cambiar "80:80" por "8080:80"
# Luego acceder a http://localhost:8080

# Opción 3: Detener otros servicios
docker compose down
docker ps -a  # Ver si hay otros contenedores
docker stop <container_id>
```

---

### 6. MySQL no inicializa correctamente

**Síntomas:**
- Logs: "Waiting for mysqld to be ready"
- Aplicación no puede conectar a BD

**Soluciones:**

```bash
# 1. Ver logs detallados de MySQL
docker compose logs -f db

# Esperar hasta ver "ready for connections"

# 2. Si tarda más de 1 minuto, aumentar el timeout
# En docker-compose.yml, cambiar "retries: 3" a "retries: 10"

# 3. Verificar que el contenedor tiene suficiente RAM
docker stats

# Si el uso está en 100%, aumentar memoria en Docker Desktop

# 4. Destruir volumen de BD y empezar de nuevo
docker compose down -v
docker compose up -d
```

---

### 7. La aplicación no guarda datos entre reinicios

**Síntomas:**
- Los datos desaparecen después de `docker compose down`

**Causas:**
- Volumen de BD no configurado correctamente

**Soluciones:**

```bash
# 1. Verificar que el volumen existe en docker-compose.yml
cat docker-compose.yml | grep -A 2 "volumes:"

# Debería incluir:
# volumes:
#   db_data:
#     driver: local

# 2. Listar volúmenes de Docker
docker volume ls | grep db_data

# 3. Verificar contenido del volumen
docker inspect db_data

# 4. Si falta, reconstruir con:
docker compose down
docker compose up -d
```

---

### 8. Cambios en el código PHP no se reflejan

**Síntomas:**
- Editas `app/index.php` pero la web no cambia

**Causas:**
- Cache de Nginx
- Archivo no montado correctamente

**Soluciones:**

```bash
# 1. Comprobar que el volumen está correctamente montado
docker compose exec app ls /var/www/html/

# 2. Verificar que tu archivo fue actualizado
cat app/index.php | head -20

# 3. Limpiar caché de Nginx
docker compose exec nginx rm -rf /var/cache/nginx/*

# 4. Recargar Nginx
docker compose exec nginx nginx -s reload

# 5. Si persiste, entrar en el contenedor
docker compose exec app bash
cat /var/www/html/index.php
```

---

### 9. Errores de permisos en archivos

**Síntomas:**
- Error: "Permission denied" al acceder a archivos

**Causas:**
- Usuario no-root en Dockerfile no tiene permisos

**Soluciones:**

```bash
# 1. Verificar propietario de archivos
docker compose exec app ls -la /var/www/html/

# Debería mostrar "appuser appuser" como propietario

# 2. Si muestra "root root", ajustar permisos
docker compose exec app chown -R appuser:appuser /var/www/html/

# 3. Verificar permisos de lectura
docker compose exec app chmod -R 755 /var/www/html/

# 4. Mejor: ajustar Dockerfile
# En docker/Dockerfile verificar:
# COPY --chown=appuser:appuser ./app .
# USER appuser
```

---

### 10. La API no funciona correctamente

**Síntomas:**
- `/api.php?action=list` devuelve error 500
- JSON vacío o mal formado

**Soluciones:**

```bash
# 1. Probar manualmente
curl http://localhost/api.php?action=list

# 2. Ver respuesta HTTP completa
curl -v http://localhost/api.php?action=list

# 3. Ver logs del contenedor app
docker compose logs app

# 4. Entrar en el contenedor para debuguear
docker compose exec app bash
php -r "require 'config/database.php'; $db = new Database(); $db->connect();"

# 5. Verificar que la tabla existe
docker compose exec db mysql -u appuser -p
# Dentro de MySQL:
use todoapp;
show tables;
select * from todos;
```

---

## Comandos útiles para debugging

```bash
# Ver todos los logs
docker compose logs

# Logs en tiempo real
docker compose logs -f

# Logs de un servicio específico
docker compose logs -f app

# Últimas 50 líneas
docker compose logs --tail=50

# Entrar en un contenedor
docker compose exec app bash
docker compose exec db bash
docker compose exec nginx ash

# Ejecutar comando sin entrar
docker compose exec app php -v
docker compose exec db mysql -V

# Mostrar variables de entorno
docker compose exec app env

# Mostrar uso de recursos
docker compose stats

# Reiniciar un servicio
docker compose restart app

# Reconstruir imagen
docker compose build app

# Ver definición de un servicio
docker compose config | grep -A 20 "services:"

# Validar docker-compose.yml
docker compose config

# Detener todo sin borrar datos
docker compose stop

# Reanudar servicios parados
docker compose start

# Limpiar todo (contenedores + redes, pero no volúmenes)
docker compose down

# Limpiar todo incluyendo volúmenes
docker compose down -v
```

---

## Checklist cuando nada funciona

1. ✅ ¿Docker Desktop está corriendo? (`docker --version`)
2. ✅ ¿Los contenedores existen? (`docker compose ps`)
3. ✅ ¿Están con status "Up"? (`docker compose ps`)
4. ✅ ¿El estado dice "healthy"? (`docker compose ps`)
5. ✅ ¿Puedo acceder a `http://localhost`?
6. ✅ ¿Los logs no muestran errores? (`docker compose logs`)
7. ✅ ¿El puerto 80 está libre? (`lsof -i :80` en macOS/Linux)
8. ✅ ¿Tiene variables de entorno correctas? (`docker compose exec app env`)
9. ✅ ¿Puede conectar a la BD? (`docker compose exec app ping db`)
10. ✅ ¿Nginx puede conectar con PHP-FPM? (`docker compose exec nginx ping app`)

Si ninguno de estos funciona, una última opción:

```bash
# Destruir todo y empezar de nuevo
docker compose down -v
rm -rf .env  # Comenzar con valores por defecto
docker compose up -d --build
```

---

## Recursos para más ayuda

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
