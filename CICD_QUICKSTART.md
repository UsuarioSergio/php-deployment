# 🚀 CI/CD - Quickstart (5 minutos)

## El flujo en 3 pasos

```
1. Push a GitHub
   ↓
2. GitHub Actions construye automáticamente
   ↓
3. Desplegar en servidor con: bash deploy.sh
```

---

## Paso 1: Verificar que GitHub Actions está configurado

Tu repositorio ya tiene el workflow `.github/workflows/build-and-push.yml`.

✅ Verificar:
1. Entra en GitHub → Tu repo → Actions
2. Deberías ver "Build and Push Docker Image"
3. Click y verifica que el último push ejecutó el workflow

---

## Paso 2: Hacer push (dispara el workflow)

```bash
# En tu máquina
git add .
git commit -m "Tu cambio"
git push origin main

# Ve a GitHub Actions y verifica que se ejecuta
# Tarda 2-5 minutos
```

---

## Paso 3: En el servidor (una sola vez)

```bash
# Conectarse
ssh usuario@tu-servidor.com
cd ~/php-app

# Login en GitHub Container Registry
echo "GITHUB_TOKEN" | docker login ghcr.io -u tu-usuario --password-stdin

# Crear .env.prod
cp .env.prod.example .env.prod
nano .env.prod  # ← Cambiar credenciales
```

---

## Paso 4: Desplegar

```bash
# Opción A: Script automático
bash deploy.sh

# Opción B: Manual (si prefieres)
docker pull ghcr.io/tu-usuario/tu-repo/php-app:latest
docker compose -f docker-compose.prod.yml up -d
```

**¡Listo! Accede a `http://tu-servidor`**

---

## Actualizaciones futuras

```bash
# En tu máquina
git push origin main  # Dispara GitHub Actions

# En el servidor
bash deploy.sh  # Descarga nueva imagen y redeploy
```

---

## Variables importantes en .env.prod

```bash
GITHUB_REPOSITORY=tu-usuario/tu-repo    # Tu repo en GitHub
APP_VERSION=latest                       # O v1.2.3 para versión específica
DB_PASSWORD=CAMBIAR_EN_PRODUCCION       # Contraseña segura
```

---

## Tokens de GitHub

**Personal Access Token (para servidor):**
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token → classic
3. Selecciona scope: `read:packages`
4. Usa ese token en: `docker login ghcr.io -u usuario --password-stdin`

---

## Verificar que todo funciona

```bash
# En GitHub
# 1. Ve a Actions
# 2. Verifica que "Build and Push Docker Image" está en verde
# 3. Verifica que la imagen aparece en Packages

# En el servidor
docker compose -f docker-compose.prod.yml ps
# Deberías ver 3 servicios "Up"

docker compose -f docker-compose.prod.yml logs
# Verifica que no hay errores
```

---

## Troubleshooting rápido

| Problema | Solución |
|----------|----------|
| Workflow no se ejecuta | Push a `main` (no a otra rama) |
| "docker login failed" | Verificar token de GitHub es válido |
| "image not found" | Esperar a que GitHub Actions termine |
| "Connection refused" | Esperar 30 segundos a que MySQL inicie |

---

## Próximos pasos

1. Ver [CICD_AUTOMATIZADO.md](CICD_AUTOMATIZADO.md) para detalles
2. Leer [deploy.sh](deploy.sh) para entender qué hace
3. Configurar cron job si quieres despliegue automático

---

**¡Eso es todo! Tu CI/CD está configurado.** 🎉
