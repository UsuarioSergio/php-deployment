<?php
// app/config/database.php

class Database {
    private $host = $_ENV['DB_HOST'] ?? 'localhost';
    private $db = $_ENV['DB_DATABASE'] ?? 'todoapp';
    private $user = $_ENV['DB_USER'] ?? 'root';
    private $pass = $_ENV['DB_PASSWORD'] ?? 'root';
    private $pdo;

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
