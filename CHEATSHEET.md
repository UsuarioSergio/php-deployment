# Docker Compose Cheatsheet - PHP Deployment

## 🚀 Comandos básicos

```bash
# Levantar servicios (en background)
docker compose up -d

# Ver en vivo (sin detach)
docker compose up

# Detener servicios
docker compose down

# Eliminar también volúmenes (⚠️ borra datos)
docker compose down -v
```

## 📊 Ver estado

```bash
# Ver todos los contenedores
docker compose ps

# Ver logs en tiempo real
docker compose logs -f

# Ver logs de un servicio
docker compose logs -f app

# Últimas 100 líneas
docker compose logs --tail=100

# Ver estadísticas de recursos
docker compose stats

# Validar docker-compose.yml
docker compose config
```

## 🔄 Controlar servicios

```bash
# Reiniciar un servicio
docker compose restart app

# Parar un servicio (sin borrar)
docker compose stop app

# Reanudar servicios parados
docker compose start app

# Ejecutar comando en contenedor
docker compose exec app bash

# Sin entrar (ejecutar y salir)
docker compose exec -T app php -v

# Ver variables de entorno
docker compose exec app env

# Ver procesos dentro del contenedor
docker compose exec app ps aux
```

## 🔨 Construcción y reconstrucción

```bash
# Construir imagen (si Dockerfile cambió)
docker compose build

# Reconstruir sin caché
docker compose build --no-cache

# Construir solo un servicio
docker compose build app

# Construir y levantar
docker compose up -d --build

# Reconstruir solo uno y levantar
docker compose up -d --build app
```

## 🔍 Debugging

```bash
# Verificar conectividad entre contenedores
docker compose exec nginx ping app

# Comprobar puerto
docker compose exec app netstat -an | grep LISTEN

# Verificar variables de entorno
docker compose exec app env | grep DB_

# Ejecutar comando PHP
docker compose exec app php -r "phpinfo();"

# Ver archivo dentro del contenedor
docker compose exec app cat /var/www/html/index.php

# Copiar archivo desde contenedor
docker compose cp app:/var/www/html/index.php ./

# Copiar archivo al contenedor
docker compose cp ./index.php app:/var/www/html/
```

## 🗄️ Base de datos

```bash
# Conectarse a MySQL
docker compose exec db mysql -u appuser -p todoapp

# Dentro de MySQL
mysql> SELECT * FROM todos;
mysql> SHOW TABLES;
mysql> DESC todos;
mysql> EXIT;

# Ejecutar SQL directamente
docker compose exec db mysql -u appuser -p todoapp -e "SELECT * FROM todos;"

# Dump de BD
docker compose exec db mysqldump -u appuser -p todoapp > backup.sql

# Restaurar desde backup
docker compose exec db mysql -u appuser -p todoapp < backup.sql

# Ver logs de MySQL
docker compose logs db
```

## 🌐 Nginx

```bash
# Validar configuración
docker compose exec nginx nginx -t

# Recargar sin detener
docker compose exec nginx nginx -s reload

# Ver logs de acceso
docker compose exec nginx tail -f /var/log/nginx/access.log

# Ver logs de error
docker compose exec nginx tail -f /var/log/nginx/error.log

# Ver configuración activa
docker compose exec nginx nginx -T | grep -A 20 "server {"
```

## 🧹 Limpieza

```bash
# Borrar contenedores parados
docker compose down

# Borrar contenedores + volúmenes
docker compose down -v

# Borrar contenedores + volúmenes + imágenes
docker compose down -v --rmi all

# Borrar solo imágenes construidas
docker compose down --rmi local

# Limpiar todo (contenedores + volúmenes no usados)
docker system prune -a --volumes
```

## 🔧 Variables de entorno

```bash
# Desde .env
docker compose config | grep -A 5 "environment:"

# Cambiar variable sin editar archivo
docker compose exec app env DB_HOST=newhost php -r "echo getenv('DB_HOST');"

# Pasar variable en comando
DB_HOST=custom docker compose up -d

# Ver .env actual
cat .env
```

## 📝 Archivos importantes

```bash
# Ver docker-compose.yml
cat docker-compose.yml

# Editar docker-compose.yml
nano docker-compose.yml

# Ver Dockerfile
cat docker/Dockerfile

# Ver configuración nginx
cat nginx/nginx.conf

# Ver código PHP
cat app/index.php
```

## 🚨 Solución de problemas rápida

| Problema | Comando |
|----------|---------|
| Contenedor no inicia | `docker compose logs app` |
| Puerto ocupado | `lsof -i :80` (macOS/Linux) |
| MySQL no conecta | `docker compose exec app ping db` |
| PHP muestra error | `docker compose logs app` |
| Nginx 502 | `docker compose exec nginx ping app` |
| Volumen no monta | `docker inspect <container_id> \| grep Mounts -A 10` |

## 📦 Órdenes importantes

```bash
# SETUP INICIAL
docker compose up -d --build

# DESARROLLO
docker compose up              # Ver logs en vivo
docker compose logs -f app     # Logs de app

# DEBUGGING
docker compose exec app bash   # Entrar en bash
docker compose logs           # Ver todos los logs

# LIMPIEZA
docker compose down -v        # Borrar todo

# REINICIO COMPLETO
docker compose down -v && docker compose up -d --build
```

## 🎯 Flujo típico de desarrollo

```bash
# 1. Iniciar
docker compose up -d

# 2. Editar código
nano app/index.php

# 3. Verificar cambios en localhost
# Abrir navegador: http://localhost

# 4. Si cambias Dockerfile
docker compose build app
docker compose up -d

# 5. Ver logs si hay errores
docker compose logs app

# 6. Cuando termines
docker compose down
```

## 🔐 Comandos de seguridad

```bash
# Ver usuario que ejecuta proceso
docker compose exec app id

# Ver permisos de archivos
docker compose exec app ls -la /var/www/html/

# Cambiar permisos
docker compose exec app chmod 755 /var/www/html

# Ver qué puertos están abiertos
docker compose exec app netstat -tlnp

# Ejecutar como usuario específico
docker compose exec -u appuser app bash
```

## 🚀 Optimización

```bash
# Ver tamaño de imágenes
docker images | grep php-deployment

# Ver uso de recursos en tiempo real
docker compose stats

# Ver capas de una imagen
docker history <image_id>

# Limpiar contenedores sin usar
docker container prune

# Limpiar volúmenes sin usar
docker volume prune

# Limpiar redes sin usar
docker network prune
```

## 📊 Información del sistema

```bash
# Versión de Docker
docker --version
docker compose version

# Información detallada del contenedor
docker compose inspect app

# Ver variables de red
docker compose exec app ip addr show

# Ver DNS
docker compose exec app cat /etc/resolv.conf

# Ver punto de montaje
docker compose exec app mount | grep /var/www
```

## 💾 Backup y restore

```bash
# Backup de BD
docker compose exec db mysqldump -u appuser -p todoapp | gzip > backup.sql.gz

# Restore de BD
gunzip < backup.sql.gz | docker compose exec -T db mysql -u appuser -p todoapp

# Backup de volumen
docker run --rm -v db_data:/data -v $(pwd):/backup ubuntu tar czf /backup/db_backup.tar.gz /data

# Restore de volumen
docker run --rm -v db_data:/data -v $(pwd):/backup ubuntu tar xzf /backup/db_backup.tar.gz -C /
```

## 🔗 Redes

```bash
# Ver redes disponibles
docker network ls

# Ver contenedores en una red
docker network inspect <network_name>

# Ver IP de un contenedor
docker inspect <container_id> | grep "IPAddress"

# Desde dentro del contenedor, ver red
docker compose exec app ip route show

# Resolver nombre de host
docker compose exec app getent hosts db
```

## 📝 Notas útiles

- Usa `-f` con `docker compose logs` para ver en tiempo real
- Usa `-T` con `docker compose exec` cuando no necesites TTY
- Los volúmenes persisten aunque borres contenedores (sin `-v`)
- Las redes Docker usan DNS interno (usa nombre del servicio)
- Las variables de .env se expanden en docker-compose.yml
- Los cambios en código PHP se ven instantáneamente (volumen)
- Los cambios en Dockerfile requieren reconstruir la imagen
