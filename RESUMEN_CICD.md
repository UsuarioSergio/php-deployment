# ✅ CI/CD Automatizado - Resumen de implementación

## Qué se creó

He creado un **flujo CI/CD completo y automático** con GitHub Actions que:

✅ **Automáticamente construye** la imagen Docker en cada push a `main`  
✅ **Automáticamente publica** en GitHub Container Registry (ghcr.io)  
✅ **En el servidor solo necesitas hacer**: `docker pull` + `docker compose up -d`  

---

## 📁 Archivos nuevos

### 1. **.github/workflows/build-and-push.yml** - El corazón del CI/CD

```yaml
# Qué hace:
- Detecta push a main
- Construye Dockerfile
- Publica en ghcr.io con tags automáticos
- Usa caché de Docker para builds rápidos
- Tarda: 2-5 minutos
```

**Tags generados automáticamente:**
- `ghcr.io/tu-usuario/repo/php-app:latest` (rama main)
- `ghcr.io/tu-usuario/repo/php-app:main-abc123` (commit específico)
- `ghcr.io/tu-usuario/repo/php-app:v1.2.3` (releases/tags)

### 2. **docker-compose.prod.yml** - Configuración para producción

```yaml
# Diferencias respecto a docker-compose.yml:
- Image: usa ghcr.io en lugar de build local
- restart: always (en lugar de unless-stopped)
- Logging: limita tamaño de logs
- Health checks más agresivos
- Montajes en read-only donde sea posible
```

### 3. **.env.prod.example** - Variables de producción

```
GITHUB_REPOSITORY=tu-usuario/tu-repo
APP_VERSION=latest  # O v1.2.3 para versión específica
DB_PASSWORD=...     # Cambiar en producción
```

### 4. **CICD_AUTOMATIZADO.md** - Guía completa

```
- Arquitectura del flujo
- Setup paso a paso
- Cómo funciona GitHub Actions
- Despliegue en servidor
- Troubleshooting
- 3000+ líneas de documentación
```

### 5. **deploy.sh** + **deploy.ps1** - Scripts de despliegue

```bash
# En el servidor:
bash deploy.sh
# O en Windows:
powershell -ExecutionPolicy Bypass -File deploy.ps1

# Qué hace:
# - Verifica Docker
# - Carga variables de entorno
# - Autentica con GHCR
# - Descarga imagen
# - Hace backup de BD
# - Levanta servicios
# - Verifica health checks
```

---

## 🔄 Flujo de despliegue completo

### Día 1: Configuración inicial (una sola vez)

```bash
# 1. En GitHub: Habilitar Actions
# Settings → Actions → Allow workflows

# 2. En tu máquina: Push a main
git add .
git commit -m "Initial commit"
git push origin main
# ✅ GitHub Actions comienza automáticamente
# Ve a Actions tab para ver progreso

# 3. En el servidor: Clone + setup
ssh usuario@servidor
cd ~/php-app
git clone https://github.com/tu-usuario/tu-repo.git .
cp .env.prod.example .env.prod
nano .env.prod  # ← Configurar credenciales
echo "TOKEN" | docker login ghcr.io -u tu-usuario --password-stdin

# 4. Desplegar
bash deploy.sh
# ✅ App en vivo en 5 minutos
```

### Día 10: Actualizar código (automático)

```bash
# En tu máquina
nano app/index.php  # Cambios
git add .
git commit -m "Fix bug"
git push origin main
# ✅ GitHub Actions automáticamente:
#    - Construye la imagen
#    - La publica en ghcr.io
#    - Listo para desplegar

# En el servidor (manual o con cron job)
bash deploy.sh
# ✅ Cambios en vivo en 5 minutos
```

---

## 📊 Arquitectura del flujo

```
Tu máquina → git push
             ↓
         GitHub
             ↓
      GitHub Actions (ubuntu-latest)
      - Construye Dockerfile
      - Ejecuta tests (opcional)
      - Publica en ghcr.io
             ↓
    GitHub Container Registry
    ghcr.io/.../php-app:latest
             ↓
       Tu servidor
       docker pull → docker compose up -d
             ↓
         ¡EN VIVO!
```

---

## 🎯 Cómo usar en tu proyecto

### Paso 1: Copiar archivos

```bash
# Los archivos ya están en php-deployment/:
.github/workflows/build-and-push.yml  ← GitHub Actions
docker-compose.prod.yml               ← Para producción
.env.prod.example                     ← Variables
deploy.sh / deploy.ps1                ← Scripts
CICD_AUTOMATIZADO.md                  ← Guía
```

### Paso 2: Configurar GitHub Actions (automático)

No hay que hacer nada. Los workflows se activan solos cuando haces push.

### Paso 3: En el servidor (una sola vez)

```bash
# Autenticar en GHCR
echo "GITHUB_TOKEN" | docker login ghcr.io -u tu-usuario --password-stdin

# Usar script de despliegue
bash deploy.sh
```

### Paso 4: Actualizaciones futuras

```bash
# Simplemente:
bash deploy.sh
```

---

## 🔐 Seguridad

✅ **Credenciales seguras:**
- `.env.prod` NO va en git (está en .gitignore)
- GitHub Token se genera automáticamente
- Imágenes privadas (requieren autenticación)

✅ **Auditoría completa:**
- Historial en GitHub Actions
- Logs de cada build
- Quién, cuándo y qué se desplegó

---

## 📋 Checklist de setup

- [ ] El repositorio existe en GitHub
- [ ] El archivo `.github/workflows/build-and-push.yml` está commitado
- [ ] Hiciste push a `main`
- [ ] Ves el workflow ejecutándose en Actions tab
- [ ] El workflow termina en verde (✅)
- [ ] La imagen aparece en Packages
- [ ] Autenticaste en el servidor: `docker login ghcr.io`
- [ ] Ejecutaste `bash deploy.sh` en el servidor
- [ ] Accediste a `http://servidor/` y funciona

---

## 🚀 Comandos rápidos

### En tu máquina
```bash
# Trigger GitHub Actions
git push origin main

# Ver progreso
# Ve a GitHub → Actions tab
```

### En el servidor
```bash
# Desplegar
bash deploy.sh

# Ver logs
docker compose -f docker-compose.prod.yml logs -f

# Actualizar sin bajar
docker pull ghcr.io/usuario/repo/php-app:latest
docker compose -f docker-compose.prod.yml up -d

# Rollback a versión anterior
APP_VERSION=v1.0.0 docker compose -f docker-compose.prod.yml up -d
```

---

## 🎓 Qué aprendes

✅ GitHub Actions y workflows  
✅ CI/CD automatizado  
✅ Docker Registry  
✅ Multi-environment (dev/prod)  
✅ Infrastructure as Code  
✅ Despliegue automatizado  
✅ Versionado de aplicaciones  
✅ Rollback y recuperación  

---

## ❓ Preguntas frecuentes

**P: ¿Por qué ghcr.io y no Docker Hub?**  
R: Porque está integrado con GitHub y no necesitas cuenta aparte.

**P: ¿Cuánto tarda el build?**  
R: 2-5 minutos la primera vez. Próximos builds usan caché (1-2 minutos).

**P: ¿Puedo usar otro registry?**  
R: Sí. Cambia `ghcr.io` por `docker.io` o `registry.gitlab.com` en el workflow.

**P: ¿Qué pasa si el workflow falla?**  
R: La imagen anterior sigue en el registry. Puedes desplegar esa en su lugar.

**P: ¿Puedo automatizar el despliegue en servidor?**  
R: Sí, con webhooks o cron job. Ver CICD_AUTOMATIZADO.md para detalles.

---

## 📚 Documentación

- **CICD_AUTOMATIZADO.md** - Guía completa (TODO sobre CI/CD)
- **deploy.sh/ps1** - Scripts listos para usar
- **.github/workflows/** - Workflow de GitHub Actions

---

## 🎉 Resumen

Ahora tienes:

✅ **Build automático** - Cada push construye la imagen  
✅ **Publish automático** - Publica en ghcr.io  
✅ **Despliegue simple** - Solo `bash deploy.sh` en el servidor  
✅ **Versionado** - Tags automáticos de versión  
✅ **Seguro** - Credenciales fuera del repositorio  
✅ **Auditable** - Logs completos en GitHub  
✅ **Reversible** - Rollback a versión anterior si falla  

**El flujo perfecto de CI/CD para tu aplicación Docker.** 🚀

---

*Para más detalles, ver [CICD_AUTOMATIZADO.md](CICD_AUTOMATIZADO.md)*
