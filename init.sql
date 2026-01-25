-- init.sql
-- Script de inicialización de base de datos
-- Se ejecuta automáticamente al crear el contenedor MySQL por primera vez

USE todoapp;

CREATE TABLE IF NOT EXISTS todos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created (created_at),
    INDEX idx_completed (completed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Datos de ejemplo (opcional)
INSERT INTO todos (title, completed) VALUES
    ('Configurar Docker Compose', true),
    ('Desplegar en producción', true),
    ('Configurar CI/CD', false),
    ('Añadir HTTPS', false)
ON DUPLICATE KEY UPDATE title=title;
