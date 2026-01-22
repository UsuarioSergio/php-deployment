# 📚 PHP Deployment - Índice de contenidos

Bienvenido a la actividad **PHP Deployment**. Esta carpeta contiene todo lo que necesitas para aprender a desplegar una aplicación multi-contenedor con Docker, Nginx, PHP-FPM y MySQL.

## 🎯 Por dónde empezar

### ⚡ Si tienes 15 minutos
1. Lee [QUICKSTART.md](QUICKSTART.md) - Guía rápida
2. Ejecuta `docker compose up -d`
3. Accede a `http://localhost`

### 📖 Si tienes 2-3 horas
1. Lee [README.md](README.md) - Guía completa paso a paso
2. Sigue cada paso del 0 al 12
3. Realiza las pruebas de la sección 9
4. Verifica el checklist de éxito en paso 12

### 🔧 Si algo no funciona
1. Consulta [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Busca tu error específico
3. Sigue las soluciones sugeridas

## 📋 Estructura de archivos

```
php-deployment/
├── README.md                 ← Guía completa (empieza aquí)
├── QUICKSTART.md            ← Versión rápida (5 min)
├── TROUBLESHOOTING.md       ← Solución de problemas
├── EXTENSIONES.md           ← Actividades adicionales
├── SOLUCIONARIO.md          ← Soluciones a ejercicios
├── setup.sh                 ← Script de setup (Linux/macOS)
├── setup.ps1                ← Script de setup (Windows)
├── INDEX.md                 ← Este archivo
├── docker-compose.yml       ← Orquestación Docker
├── .env.example             ← Variables de entorno (ejemplo)
├── .dockerignore            ← Archivos a ignorar en build
├── docker/
│   └── Dockerfile           ← Imagen PHP-FPM
├── nginx/
│   └── nginx.conf          ← Configuración Nginx
└── app/
    ├── index.php            ← Página principal
    ├── api.php              ← API REST
    └── config/
        └── database.php     ← Configuración BD
```

## 📖 Guías disponibles

| Archivo | Propósito | Duración |
|---------|-----------|----------|
| [README.md](README.md) | Guía completa paso a paso | 2-3 horas |
| [QUICKSTART.md](QUICKSTART.md) | Versión rápida para empezar rápido | 15 minutos |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Solución de problemas comunes | Bajo demanda |
| [EXTENSIONES.md](EXTENSIONES.md) | 10 actividades para extender | 1-2 horas c/u |
| [SOLUCIONARIO.md](SOLUCIONARIO.md) | Soluciones a actividades bonus | Referencia |

## 🚀 Instalación rápida

### Opción 1: Script automático

**Linux/macOS:**
```bash
bash setup.sh
```

**Windows PowerShell:**
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

### Opción 2: Manual

```bash
# 1. Copiar variables de entorno
cp .env.example .env

# 2. Levantar contenedores
docker compose up -d

# 3. Esperar a que MySQL inicialice
# (Esto puede tardar 30 segundos)

# 4. Verificar
docker compose ps
# Los 3 servicios deberían mostrar "Up (healthy)"

# 5. Acceder
# Abre http://localhost en tu navegador
```

## 📌 Concepto general

Esta actividad te enseña a desplegar una aplicación web completa con múltiples componentes:

```
Tu navegador
    ↓ HTTP
┌─────────────────┐
│ Nginx (puerto 80)
│ - Reverse proxy
│ - Archivos estáticos
└────────┬────────┘
         ↓ FastCGI
┌─────────────────────────┐
│ PHP-FPM (puerto 9000)
│ - Lógica de aplicación
└────────┬────────────────┘
         ↓ SQL
┌─────────────────────────┐
│ MySQL (puerto 3306)
│ - Base de datos
└─────────────────────────┘
```

Todos conectados por una **red Docker privada** y con **volúmenes** para persistencia de datos.

## 🎓 Qué aprenderás

✅ Crear Dockerfiles optimizados  
✅ Usar Docker Compose para multi-contenedor  
✅ Configurar Nginx como reverse proxy  
✅ Comunicación entre contenedores  
✅ Volúmenes y persistencia  
✅ Variables de entorno  
✅ Health checks  
✅ Debugging de aplicaciones containerizadas  
✅ Buenas prácticas de seguridad  
✅ Preparación para CI/CD  

## 📊 Actividades disponibles

### Actividad Base (4-5 puntos)
- Desplegar la aplicación completa
- Verificar todos los contenedores
- Probar funcionalidad

### Actividades Bonus (2 puntos c/u)
1. ✅ Crear `init.sql` para inicializar BD
2. ✅ Crear `Dockerfile.prod` para producción
3. ✅ Crear `docker-compose.prod.yml`
4. ✅ Implementar validación de entrada
5. ✅ Crear script de backup automático
6. ✅ Integración con GitHub Actions
7. ✅ Pruebas de carga con Apache Bench
8. ✅ Configurar Prometheus para monitoreo
9. ✅ Documentar API con Swagger
10. ✅ Compilar para múltiples arquitecturas

Ver [SOLUCIONARIO.md](SOLUCIONARIO.md) para soluciones de todas las actividades.

## 🔍 Verificación

### Checklist mínimo

- [ ] `docker compose ps` muestra 3 servicios "Up (healthy)"
- [ ] `http://localhost` carga sin errores
- [ ] Muestra "✅ Conexión a MySQL correcta"
- [ ] Prueba API: `curl http://localhost/api.php?action=list`
- [ ] Los datos persisten al recargar

### Checklist avanzado

- [ ] Health checks funcionan
- [ ] Logs accesibles sin errores
- [ ] Puedes entrar en contenedores
- [ ] Comprendiste cada componente
- [ ] Completaste al menos 1 actividad bonus

## 🆘 Ayuda rápida

| Problema | Solución |
|----------|----------|
| Docker no inicia | Instala Docker Desktop |
| Contenedores no arrancan | Ver `docker compose logs` |
| MySQL no está listo | Esperar 30 segundos más |
| Aplicación muestra error | Ver `docker compose logs app` |
| Puerto 80 en uso | Ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Datos desaparecen | Revisar volúmenes en docker-compose.yml |

## 📚 Recursos externos

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PHP-FPM Manual](https://www.php.net/manual/en/install.fpm.php)
- [MySQL 8.0 Reference](https://dev.mysql.com/doc/refman/8.0/en/)

## 🎯 Objetivos de aprendizaje

Al completar esta actividad serás capaz de:

1. ✅ Entender la arquitectura de una aplicación web multi-contenedor
2. ✅ Crear Dockerfiles optimizados para diferentes escenarios
3. ✅ Orquestar múltiples contenedores con Docker Compose
4. ✅ Configurar un reverse proxy con Nginx
5. ✅ Implementar persistencia de datos con volúmenes
6. ✅ Usar variables de entorno para configuración
7. ✅ Debuguear problemas en aplicaciones containerizadas
8. ✅ Implementar health checks
9. ✅ Aplicar buenas prácticas de seguridad
10. ✅ Preparar una aplicación para despliegue en producción

## ✨ Consejos

1. **Lee el README.md primero** - Está bien estructurado paso a paso
2. **No tengas prisa** - Entiende cada concepto, no solo copies comandos
3. **Experimenta** - Modifica archivos y ve qué pasa
4. **Revisa los logs** - `docker compose logs -f` es tu mejor amigo
5. **Documenta tu aprendizaje** - Toma notas sobre qué aprendes
6. **Prueba extensiones** - Las actividades bonus son más interesantes
7. **Pide ayuda** - Si algo no funciona, usa TROUBLESHOOTING.md primero

## 📝 Evaluación esperada

- **Actividad base completada:** 4-5 puntos
- **Actividades bonus (≥3):** 5 puntos
- **Código documentado:** 2 puntos
- **Buen manejo de errores:** 2 puntos
- **Pruebas realizadas:** 2 puntos
- **Presentación:** 4 puntos
- **Total:** 20 puntos

## 🚀 Después de esta actividad

Una vez completes esto, puedes:

1. Mejorar la aplicación con más funcionalidades
2. Configurar CI/CD con GitHub Actions
3. Subir la imagen a Docker Hub o GitHub Container Registry
4. Desplegar en producción (AWS, DigitalOcean, etc.)
5. Implementar monitoreo con Prometheus/Grafana
6. Escalar la aplicación con Kubernetes

## 📞 Contacto y soporte

Si tienes problemas:
1. Revisa [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Consulta los logs: `docker compose logs`
3. Pregunta en clase (trae los logs)
4. Revisa el [README.md](README.md) de nuevo

---

**¡Bienvenido a la aventura de Docker!** 🚀

Empieza por [README.md](README.md) o ejecuta `bash setup.sh` y ¡vamos!
