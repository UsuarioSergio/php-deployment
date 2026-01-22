<?php
// app/api.php - API REST simple

header('Content-Type: application/json');

require_once 'config/database.php';

$db = new Database();
$pdo = $db->connect();

$action = $_GET['action'] ?? 'list';

try {
    switch ($action) {
        case 'list':
            $stmt = $pdo->query("SELECT * FROM todos ORDER BY created_at DESC");
            echo json_encode(['success' => true, 'data' => $stmt->fetchAll()]);
            break;
            
        case 'add':
            $title = $_POST['title'] ?? null;
            if (!$title) {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'Título requerido']);
                break;
            }
            $stmt = $pdo->prepare("INSERT INTO todos (title) VALUES (?)");
            $stmt->execute([$title]);
            echo json_encode(['success' => true, 'id' => $pdo->lastInsertId()]);
            break;
            
        case 'toggle':
            $id = $_POST['id'] ?? null;
            if (!$id) {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'ID requerido']);
                break;
            }
            $stmt = $pdo->prepare("UPDATE todos SET completed = NOT completed WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
            break;
            
        case 'delete':
            $id = $_POST['id'] ?? null;
            if (!$id) {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'ID requerido']);
                break;
            }
            $stmt = $pdo->prepare("DELETE FROM todos WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Acción no válida']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
