# Deployment sin código fuente en el servidor

Objetivo: desplegar usando solo imágenes versionadas desde el registry (GHCR/Docker Hub) sin requerir el árbol de código en el servidor de producción.

## Qué debe estar en el servidor

- `docker-compose.prod.yml` apuntando a imágenes con tag inmutable (ej. `app:1.2.3`, `nginx:1.25.x`, `mysql:8.0.x`).
- `.env.prod` con credenciales y configuración (DB, host, etc.).
- `init.sql` opcional para la primera inicialización de MySQL (solo se ejecuta con volumen vacío).
- Docker Engine + Docker Compose v2 instalados.

## Ajustes de compose para "imagen-only"

- Quita los bind mounts de código en producción:
	- En `nginx`: eliminar `./app:/var/www/html:ro`.
	- En `app`: eliminar `./app:/var/www/html:ro`.
- Asegúrate de que el Dockerfile de la app copie todo el código en la imagen.

## Flujo de deploy manual

```bash
# 1) Bajar stack actual (conserva datos)
docker compose -f docker-compose.prod.yml down

# 2) Traer imágenes nuevas (pull selectivo o completo)
docker compose -f docker-compose.prod.yml pull            # todas
# o solo servicios cambiados
docker compose -f docker-compose.prod.yml pull app nginx

# 3) Levantar con las nuevas imágenes
docker compose -f docker-compose.prod.yml up -d
```

## Verificación rápida

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs --tail=50
curl -f http://localhost:8083/health.php   # ajusta puerto/NAT
```

## Cambio de versiones

- Edita `docker-compose.prod.yml` (o variables en `.env.prod`) para apuntar a nuevos tags de imágenes.
- Usa siempre tags inmutables (evita `latest`).
- Después de cambiar versiones: `docker compose pull` + `docker compose up -d`.

## Rollback

- Mantén el tag anterior documentado.
- Para volver atrás: cambia el tag al anterior, `docker compose pull`, `docker compose up -d`.

## MySQL: consideraciones

- El volumen `db_data` conserva los datos. No uses `down -v` en producción si quieres mantener la base.
- Para upgrades mayores de MySQL: haz backup previo (`mysqldump`), revisa notas de migración, prueba antes en staging.

## Minimalismo en el servidor

- No necesitas el repo ni el código fuente; solo los archivos declarativos (`docker-compose.prod.yml`, `.env.prod`, `init.sql` opcional) y los volúmenes de datos.
- Los logs y backups se gestionan vía Docker (`docker compose logs`, `mysqldump`).

## Resumen operativo

- App nueva: `pull app` → `up -d`.
- Nginx nuevo: `pull nginx` → `up -d`.
- MySQL minor: backup opcional → `pull db` → `up -d`; mayor: backup obligatorio + pruebas previas.
- Verificar siempre health y logs tras el despliegue.
