# 🚀 CI/CD Automatizado - Despliegue en Producción

## Flujo completo de CI/CD

Este documento explica cómo tu aplicación se despliega **automáticamente** desde GitHub hasta producción.

---

## 📊 Arquitectura del flujo

```
┌──────────────────────────────────────────────────────────┐
│ Tu máquina local                                          │
│ git push origin main                                      │
└────────────────┬─────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────────────┐
│ GitHub Repository                                        │
│ - Webhook de push detecta cambios                        │
│ - Dispara workflow build-and-push.yml                    │
└────────────────┬─────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────────────┐
│ GitHub Actions (ubuntu-latest)                          │
│ - Construye Dockerfile                                   │
│ - Ejecuta tests (opcional)                              │
│ - Publica imagen en ghcr.io                             │
└────────────────┬─────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────────────┐
│ GitHub Container Registry (ghcr.io)                     │
│ ghcr.io/tu-usuario/tu-repo/php-app:latest             │
│ ghcr.io/tu-usuario/tu-repo/php-app:main-abc123        │
└────────────────┬─────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────────────┐
│ Servidor de Producción (tu VPS/nube)                   │
│ docker pull ghcr.io/...                                │
│ docker compose -f docker-compose.prod.yml up -d        │
└──────────────────────────────────────────────────────────┘
```

---

## ✅ Paso 1: Configurar el repositorio GitHub

### 1.1 Crear el repositorio (si aún no existe)

```bash
# En tu máquina local
git init
git add .
git commit -m "Initial commit: PHP deployment with Docker"
git branch -M main
git remote add origin https://github.com/tu-usuario/tu-repo.git
git push -u origin main
```

### 1.2 Verificar que los archivos están en su lugar

El repositorio debe tener esta estructura:

```
tu-repo/
├── .github/
│   └── workflows/
│       └── build-and-push.yml        ← Workflow automático
├── app/
│   ├── index.php
│   ├── api.php
│   └── config/database.php
├── docker/
│   └── Dockerfile
├── nginx/
│   └── nginx.conf
├── docker-compose.yml
├── docker-compose.prod.yml           ← Para producción
├── .env.example
├── .env.prod.example
└── README.md
```

---

## 🔐 Paso 2: Configurar permisos en GitHub (primero y último paso manual)

El workflow necesita **permiso para publicar imágenes** en GitHub Container Registry.

### 2.1 Habilitar GitHub Actions

1. Ve a tu repositorio en GitHub
2. Settings → Actions → General
3. Selecciona "Allow all actions and reusable workflows"
4. Click "Save"

### 2.2 Configurar permisos de workflow

1. Settings → Actions → General → Workflow permissions
2. Selecciona:
   - ✅ "Read and write permissions"
   - ✅ "Allow GitHub Actions to create and approve pull requests"
3. Click "Save"

**Nota:** El token `GITHUB_TOKEN` se genera automáticamente y se usa para publicar en GHCR.

---

## 🔄 Paso 3: Hacer push y activar el workflow

### 3.1 Trigger automático

Simplemente haz push a `main`:

```bash
# Hacer cambios en tu código
echo "# Mi app" > README.md

# Hacer commit y push
git add .
git commit -m "Update README"
git push origin main
```

### 3.2 Ver el workflow en acción

1. Ve a tu repositorio en GitHub
2. Click en la pestaña "Actions"
3. Verás el workflow "Build and Push Docker Image" ejecutándose
4. Click en él para ver logs en tiempo real

### 3.3 Qué hace el workflow

```
1. ✅ Descarga tu código
2. ✅ Configura Docker Buildx (para builds más rápidos)
3. ✅ Inicia sesión en ghcr.io (GitHub Container Registry)
4. ✅ Construye la imagen Docker
5. ✅ Publica la imagen con tags:
     - ghcr.io/tu-usuario/tu-repo/php-app:latest
     - ghcr.io/tu-usuario/tu-repo/php-app:main-abc123def...
     - (otros tags según versión)
6. ✅ Completa (2-5 minutos)
```

---

## 📦 Paso 4: Desplegar en tu servidor de producción

Una vez que el workflow termina exitosamente, tu imagen está en GHCR lista para usar.

### 4.1 Configuración inicial en el servidor (una sola vez)

```bash
# Conectarse al servidor
ssh usuario@tu-servidor.com

# Crear directorio para la app
mkdir -p ~/php-app
cd ~/php-app

# Descargar los archivos de configuración
git clone https://github.com/tu-usuario/tu-repo.git .
# O si prefieres, solo copia los archivos necesarios:
# - docker-compose.prod.yml
# - nginx/nginx.conf
# - app/ (o mount via volumen)
# - .env.prod

# Crear archivo de variables
cp .env.prod.example .env.prod

# IMPORTANTE: Editar con valores reales
nano .env.prod

# Debe tener:
# GITHUB_REPOSITORY=tu-usuario/tu-repo
# DB_PASSWORD=algo-muy-seguro-aqui
# DB_ROOT_PASSWORD=otro-password-seguro
```

### 4.2 Autenticar con GitHub Container Registry

Necesitas hacer login para poder descargar la imagen:

```bash
# Generar Personal Access Token en GitHub:
# 1. GitHub → Settings → Developer settings → Personal access tokens
# 2. Generate new token → ghcr (classic)
# 3. Selecciona scopes: read:packages
# 4. Copy el token

# En el servidor:
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u tu-usuario --password-stdin

# Verificar que funciona
docker pull ghcr.io/tu-usuario/tu-repo/php-app:latest
```

### 4.3 Levantar la aplicación

```bash
# Descargar la última imagen publicada
docker pull ghcr.io/tu-usuario/tu-repo/php-app:latest

# Levantar todo (MySQL, PHP-FPM, Nginx)
docker compose -f docker-compose.prod.yml up -d

# Verificar
docker compose -f docker-compose.prod.yml ps

# Ver logs
docker compose -f docker-compose.prod.yml logs -f
```

---

## 🔄 Paso 5: Actualizar la aplicación (flujo normal)

Una vez configurado, el despliegue es **totalmente automático**:

### En desarrollo (tu máquina)

```bash
# Haces cambios en tu código
nano app/index.php

# Commit y push
git add .
git commit -m "Fix bug en index.php"
git push origin main

# Esperas 2-5 minutos a que GitHub Actions construya
# Ves el progreso en Actions tab
```

### En producción (servidor)

```bash
# Simplemente pulls la última imagen y reinicia
docker pull ghcr.io/tu-usuario/tu-repo/php-app:latest
docker compose -f docker-compose.prod.yml up -d

# Los cambios están en vivo
```

**Eso es todo.** No necesitas recompiladores, no hay "funciona en mi máquina", todo está sincronizado.

---

## 📋 Versiones de imagen (tags)

El workflow genera automáticamente varios tags:

| Tag | Cuándo se usa | Ejemplo |
|-----|--------------|---------|
| `latest` | Siempre en la rama main | `ghcr.io/usuario/repo/php-app:latest` |
| `main-abc123` | Cada push específico | `ghcr.io/usuario/repo/php-app:main-abc123def456` |
| `v1.2.3` | Cuando haces release/tag | `ghcr.io/usuario/repo/php-app:v1.2.3` |

### Usar versión específica en producción (opcional)

```bash
# En .env.prod
APP_VERSION=v1.2.3

# En docker-compose.prod.yml
image: ghcr.io/${GITHUB_REPOSITORY}/php-app:${APP_VERSION}

# Luego
docker compose -f docker-compose.prod.yml up -d
```

---

## 🛡️ Seguridad

### ✅ Lo que está protegido

1. **Credenciales de BD** → En `.env.prod` (no en git)
2. **GitHub Token** → Generado automáticamente y seguro
3. **Imagen privada** → Solo tú puedes descargarla (requiere login)
4. **Histórico de builds** → Auditoría completa en GitHub Actions

### ⚠️ NO hacer NUNCA

```bash
# ❌ NO hacer commit de .env.prod
# ❌ NO guardar GITHUB_TOKEN en repositorio
# ❌ NO usar 'latest' en producción crítica (usa versión específica)
# ❌ NO hacer public la imagen si tiene datos sensibles
```

---

## 🔧 Troubleshooting

### Problema: Workflow falla con "Permission denied"

**Causa:** El usuario no tiene permisos de escritura en ghcr.io

**Solución:**
```bash
# Ve a Settings → Actions → General
# Selecciona "Read and write permissions"
# Reintenta el push
```

### Problema: "image not found" en servidor

**Causa:** No autenticaste con ghcr.io o el token expiró

**Solución:**
```bash
docker logout ghcr.io
echo "YOUR_TOKEN" | docker login ghcr.io -u tu-usuario --password-stdin
docker pull ghcr.io/tu-usuario/tu-repo/php-app:latest
```

### Problema: Workflow tarda mucho (>10 min)

**Causa:** GitHub Actions está ocupado o hay muchas capas de caché

**Solución:** Es normal, espera. Próximos builds serán más rápidos (usan caché).

### Problema: "docker-compose.prod.yml" no encontrado

**Causa:** Archivo no está en el repositorio

**Solución:** Asegúrate de haber hecho commit:
```bash
git add docker-compose.prod.yml
git commit -m "Add production compose"
git push
```

---

## 📊 Monitoreo

### Ver logs del workflow en GitHub

1. Repository → Actions
2. Click en el workflow más reciente
3. Expande "Build and Push Docker Image"
4. Lee los logs de cada paso

### Ver logs en el servidor

```bash
# Logs de todo
docker compose -f docker-compose.prod.yml logs -f

# Logs de un servicio
docker compose -f docker-compose.prod.yml logs -f app

# Ver eventos
docker events
```

---

## 🚀 Ejemplo completo paso a paso

### Día 1: Setup inicial

```bash
# En tu máquina
cd ~/mi-proyecto
git add .
git commit -m "Initial commit"
git push origin main
# ✅ GitHub Actions comienza a construir automáticamente

# En el servidor (una sola vez)
ssh usuario@servidor.com
cd ~/php-app
git clone https://github.com/tu-usuario/tu-repo.git .
cp .env.prod.example .env.prod
nano .env.prod  # ← Configurar credenciales
echo "TOKEN" | docker login ghcr.io -u tu-usuario --password-stdin
docker pull ghcr.io/tu-usuario/tu-repo/php-app:latest
docker compose -f docker-compose.prod.yml up -d
# ✅ App está en vivo
```

### Día 5: Actualizar la app

```bash
# En tu máquina
nano app/index.php  # Haces cambios
git add app/index.php
git commit -m "Improve UI"
git push origin main
# ✅ GitHub Actions construye automáticamente

# En el servidor (automático o manual)
docker pull ghcr.io/tu-usuario/tu-repo/php-app:latest
docker compose -f docker-compose.prod.yml up -d
# ✅ Cambios en vivo en 5 minutos
```

---

## 📈 Ventajas de este flujo

| Ventaja | Beneficio |
|---------|-----------|
| **Automatizado** | No hay errores manuales |
| **Rápido** | Minutos entre push y vivo |
| **Auditable** | Logs en GitHub Actions |
| **Reproducible** | Mismo Dockerfile = mismo resultado |
| **Rollback fácil** | Vuelve a una versión anterior si falla |
| **Escalable** | Mismo flujo para múltiples servidores |
| **Seguro** | Credenciales nunca se exponen |

---

## 🎯 Cheatsheet de comandos

### En tu máquina

```bash
# Hacer push (dispara GitHub Actions)
git add .
git commit -m "Tu mensaje"
git push origin main

# Ver tags
git tag -l

# Crear release (genera tag de versión)
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0
```

### En el servidor

```bash
# Autenticación (una sola vez)
echo "TOKEN" | docker login ghcr.io -u usuario --password-stdin

# Descargar última imagen
docker pull ghcr.io/usuario/repo/php-app:latest

# Levantar/actualizar
docker compose -f docker-compose.prod.yml up -d

# Ver estado
docker compose -f docker-compose.prod.yml ps

# Ver logs
docker compose -f docker-compose.prod.yml logs -f app
```

---

## 🔍 Verificación de que todo funciona

✅ **GitHub Actions:**
1. Haz push a main
2. Ve a Actions tab
3. Verifica que el workflow "Build and Push Docker Image" se ejecute
4. Debe completar en verde ✅

✅ **GitHub Container Registry:**
1. Ve a tu repositorio
2. Packages (esquina derecha)
3. Verifica que `php-app` aparece con tags
4. Click en él para ver tamaño e información

✅ **Servidor:**
1. Verifica que `docker pull` descarga sin errores
2. Verifica que `docker compose ps` muestra 3 servicios corriendo
3. Accede a la app: `curl http://localhost`

---

## 📚 Recursos

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Buildx](https://docs.docker.com/build/architecture/)
- [GitHub Secrets Management](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

**¡Tu aplicación ahora tiene CI/CD completamente automatizado!** 🎉

Desde ahora, cada push automáticamente:
1. Construye la imagen ✅
2. La publica en GHCR ✅
3. La puedes desplegar en producción ✅
