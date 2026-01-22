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
