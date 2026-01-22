# Guía Rápida - PHP Deployment (TL;DR)

## 🚀 Setup en 5 minutos

```bash
# 1. Descargar archivos de la actividad
git clone <repo>
cd php-deployment

# 2. Copiar variables de entorno
cp .env.example .env

# 3. Levantar los contenedores
docker compose up -d

# 4. Verificar
docker compose ps
# Output: TODOS deben estar "Up (healthy)"

# 5. Acceder a la aplicación
open http://localhost
# o en tu navegador: http://localhost
```

---

## 📁 Estructura de archivos

```
php-deployment/
├── README.md                    ← Guía completa (inicio aquí)
├── TROUBLESHOOTING.md          ← Problemas comunes
├── EXTENSIONES.md              ← Actividades adicionales
├── docker-compose.yml          ← Orquestación
├── docker/
│   └── Dockerfile              ← Imagen PHP-FPM
├── nginx/
│   └── nginx.conf              ← Configuración web
├── app/
│   ├── index.php               ← Página principal
│   ├── api.php                 ← API REST
│   └── config/
│       └── database.php        ← Conexión BD
└── .env.example                ← Variables (copiar a .env)
```

---

## 🔄 Flujo de trabajo típico

```
┌─────────────────────────────────────────────────────────┐
│ 1. DESARROLLO                                           │
│    - Editar app/index.php                              │
│    - Los cambios se ven en http://localhost instantáneamente
│    - Los datos persisten en MySQL                      │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ 2. TESTING                                              │
│    - Probar en http://localhost                        │
│    - Probar API: curl http://localhost/api.php         │
│    - Ver logs: docker compose logs                     │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ 3. BUILD (si cambias Dockerfile/dependencias)          │
│    - docker compose build --no-cache                   │
│    - docker compose up -d                              │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ 4. DESPLIEGUE (a producción)                           │
│    - Subir a registry: docker push ...                 │
│    - En servidor: docker compose -f docker-compose.prod.yml up -d
└─────────────────────────────────────────────────────────┘
```

---

## 🧠 Conceptos clave

| Concepto | Qué es | Por qué |
|----------|--------|--------|
| **Docker** | Contenedor (como una VM ligera) | Aislamiento + portabilidad |
| **Dockerfile** | Instrucciones para construir imagen | Reproducibilidad |
| **Docker Compose** | Orquesta múltiples contenedores | Gestionar app completa |
| **Nginx** | Servidor web + reverse proxy | Redirigir a PHP-FPM |
| **PHP-FPM** | Intérprete PHP | Ejecutar lógica |
| **MySQL** | Base de datos | Persistencia |
| **Volumen** | Almacenamiento persistente | No perder datos al reiniciar |
| **Red** | Conecta contenedores | Comunicación interna |

---

## 📍 URLs importantes

| URL | Qué es | Cómo probar |
|-----|--------|-----------|
| `http://localhost/` | Página principal | Navegador |
| `http://localhost/api.php?action=list` | Listar tareas | `curl` o Postman |
| `http://localhost/health.php` | Estado de servicios | Navegador |

---

## 🔧 Comandos esenciales

### Ver estado
```bash
docker compose ps              # ¿Los contenedores están corriendo?
docker compose logs -f app     # Ver logs en vivo
docker compose exec app bash   # Entrar en el contenedor
```

### Modificar
```bash
docker compose restart app     # Reiniciar un servicio
docker compose build --no-cache # Reconstruir imagen
docker compose down -v         # Borrar todo (⚠️ incluye datos)
```

### Debuguear
```bash
docker compose logs db         # Ver qué hace MySQL
docker compose exec app env    # Variables de entorno
docker compose exec nginx ping app  # ¿Se comunican?
```

---

## ✅ Checklist de funcionamiento

- [ ] `docker compose ps` muestra 3 servicios "Up (healthy)"
- [ ] `http://localhost` carga sin errores
- [ ] Muestra "✅ Conexión a MySQL correcta"
- [ ] Puedes crear tareas vía API
- [ ] Los datos persisten al recargar
- [ ] Los logs no muestran errores (`docker compose logs`)

Si algo falla → ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📊 Arquitectura de la aplicación

```
┌─────────────────────────────────────────────────┐
│ Tu navegador en http://localhost                │
└────────────────┬────────────────────────────────┘
                 │ (HTTP Request)
                 ↓
┌──────────────────────────────────────────────────┐
│ Nginx (reverse proxy)                            │
│ - Puerto 80                                      │
│ - Archivos estáticos                            │
│ - Redirige *.php a PHP-FPM                      │
└────────────────┬────────────────────────────────┘
                 │ (FastCGI Protocol)
                 ↓
┌──────────────────────────────────────────────────┐
│ PHP-FPM (aplicación)                            │
│ - Puerto 9000 (interno)                         │
│ - Ejecuta código PHP                            │
└────────────────┬────────────────────────────────┘
                 │ (SQL)
                 ↓
┌──────────────────────────────────────────────────┐
│ MySQL (base de datos)                           │
│ - Puerto 3306 (interno)                         │
│ - Almacena tareas                               │
└──────────────────────────────────────────────────┘
```

---

## 🎓 ¿Qué aprendes en esta actividad?

✅ Crear Dockerfiles multi-stage  
✅ Configurar Nginx como reverse proxy  
✅ Comunicación entre contenedores  
✅ Volúmenes y persistencia  
✅ Variables de entorno  
✅ Docker Compose para multi-contenedor  
✅ Health checks  
✅ Debugging de aplicaciones containerizadas  

---

## 🚫 Errores más comunes

| Error | Causa | Solución |
|-------|-------|----------|
| "Connection refused" | MySQL no está listo | Esperar a que inicialice (`docker compose logs db`) |
| "502 Bad Gateway" | PHP-FPM no responde | `docker compose restart app` |
| "Access denied" | Credenciales SQL mal | Verificar `.env` vs `docker-compose.yml` |
| "Port already in use" | Otro servicio en puerto 80 | Cambiar puerto a 8080 en `docker-compose.yml` |
| Datos desaparecen | Volumen no configurado | Ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md#7-la-aplicación-no-guarda-datos-entre-reinicios) |

---

## 🔐 Seguridad implementada

✅ Ejecutar PHP-FPM como usuario no-root (`appuser`)  
✅ Bloquear acceso a archivos sensibles (`.env`, `.git`)  
✅ Variables de entorno para credenciales (no hardcodeado)  
✅ Nginx como proxy (expone solo puerto 80)  
✅ MySQL en red privada (no accesible desde fuera)  

---

## 📈 Próximos pasos

1. **Entender cada componente** → Leer [README.md](README.md)
2. **Si algo falla** → Ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. **Extender funcionalidad** → Ver [EXTENSIONES.md](EXTENSIONES.md)
4. **Subir a registry** → GitHub Container Registry o Docker Hub
5. **CI/CD automatizado** → GitHub Actions para builds automáticos

---

## 💡 Preguntas frecuentes

**P: ¿Por qué necesito 3 contenedores?**  
R: Separación de responsabilidades = más fácil de escalar, testear y actualizar.

**P: ¿Puedo ejecutar todo en un contenedor?**  
R: Sí, pero es mala práctica. Docker está diseñado para un proceso por contenedor.

**P: ¿Por qué usar Docker si ya funciona en mi máquina?**  
R: Para garantizar que funcione igual en desarrollo, testing y producción.

**P: ¿Cuál es la diferencia entre Dockerfile y docker-compose.yml?**  
R: Dockerfile = cómo construir UNA imagen. docker-compose.yml = cómo orquestar múltiples contenedores.

**P: ¿Pierdo datos si apago los contenedores?**  
R: No si usas volúmenes. Solo si ejecutas `docker compose down -v`.

---

## 📞 Soporte

Si algo no funciona:
1. Leer el error completo (`docker compose logs`)
2. Buscar en [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. Verificar que Docker Desktop está corriendo
4. Intentar `docker compose down -v && docker compose up -d`
5. Preguntar en clase (traer logs)

---

**¡Buena suerte! 🚀**
