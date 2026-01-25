<?php
// app/config/database.php

class Database {
    private $host;
    private $db;
    private $user;
    private $pass;
    private $pdo;

    public function __construct() {
        // Read runtime env vars at construction time (PHP 8.2+: property defaults cannot use $_ENV)
        $this->host = getenv('DB_HOST') ?: 'localhost';
        $this->db   = getenv('DB_DATABASE') ?: 'todoapp';
        $this->user = getenv('DB_USER') ?: 'root';
        $this->pass = getenv('DB_PASSWORD') ?: 'root';
    }

    public function connect() {
        try {
            $this->pdo = new PDO(
                "mysql:host={$this->host};dbname={$this->db}",
                $this->user,
                $this->pass,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );
            return $this->pdo;
        } catch (PDOException $e) {
            die("Error de conexión: " . $e->getMessage());
        }
    }
}
?>
