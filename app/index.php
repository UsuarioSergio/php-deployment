<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TODO App</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; }
        .container { max-width: 800px; margin: 40px auto; padding: 0 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .content { background: white; padding: 20px; border-radius: 0 0 8px 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { padding: 15px; margin: 20px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .task-list { margin: 20px 0; }
        .task-item { padding: 12px; margin: 10px 0; background: #f9f9f9; border-left: 4px solid #007bff; border-radius: 4px; }
        .form-group { margin: 15px 0; }
        input[type="text"] { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
        button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
        button:hover { background: #0056b3; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📝 TODO App</h1>
            <p>Aplicación multi-contenedor con Docker</p>
        </div>
        <div class="content">
            <?php
            // Verificar conexión a BD
            require_once 'config/database.php';
            
            $db = new Database();
            try {
                $pdo = $db->connect();
                
                // Crear tabla si no existe
                $pdo->exec("CREATE TABLE IF NOT EXISTS todos (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(255) NOT NULL,
                    completed BOOLEAN DEFAULT FALSE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )");
                
                echo '<div class="status success">✅ Conexión a MySQL correcta</div>';
                
                // Obtener tareas
                $stmt = $pdo->query("SELECT * FROM todos ORDER BY created_at DESC");
                $todos = $stmt->fetchAll();
                
                echo '<h2>Tareas (' . count($todos) . ')</h2>';
                
                if (!empty($todos)) {
                    echo '<div class="task-list">';
                    foreach ($todos as $todo) {
                        $checked = $todo['completed'] ? '✓' : '○';
                        $buttonLabel = $todo['completed'] ? 'Marcar pendiente' : 'Marcar como realizada';
                        $buttonClass = $todo['completed'] ? 'button-secondary' : 'button-primary';
                        echo '<div class="task-item">';
                        echo '<span style="margin-right:10px;">' . $checked . '</span>';
                        echo '<span>' . htmlspecialchars($todo['title']) . '</span>';
                        echo '<form method="POST" action="api.php?action=toggle" style="display:inline; margin-left:12px;" onsubmit="toggleTask(event)">';
                        echo '<input type="hidden" name="id" value="' . (int)$todo['id'] . '">';
                        echo '<button type="submit" class="' . $buttonClass . '">' . $buttonLabel . '</button>';
                        echo '</form>';
                        echo '</div>';
                    }
                    echo '</div>';
                }
                
            } catch (Exception $e) {
                echo '<div class="status error">❌ Error de conexión: ' . $e->getMessage() . '</div>';
            }
            
            // Información del entorno
            echo '<hr style="margin: 30px 0;">';
            echo '<h3>🔧 Información del sistema</h3>';
            echo '<ul style="line-height: 1.8;">';
            echo '<li><strong>PHP Version:</strong> ' . phpversion() . '</li>';
            echo '<li><strong>Server:</strong> ' . $_SERVER['SERVER_SOFTWARE'] . '</li>';
            echo '<li><strong>Hostname:</strong> ' . gethostname() . '</li>';
            echo '<li><strong>Directorio:</strong> ' . __DIR__ . '</li>';
            echo '<li><strong>DB Host:</strong> ' . ($_ENV['DB_HOST'] ?? 'no configurado') . '</li>';
            echo '</ul>';
            
            // API info
            echo '<hr style="margin: 30px 0;">';
            echo '<h3>📡 API disponible</h3>';
            echo '<p>Prueba la API en: <code>http://localhost/api.php?action=list</code></p>';
            ?>
        </div>
    </div>
</body>
</html>
<script>
// Toggle tarea sin abandonar la página: hace fetch al endpoint y recarga si va bien
async function toggleTask(event) {
    event.preventDefault();
    const form = event.target;
    const data = new FormData(form);
    try {
        const response = await fetch('api.php?action=toggle', {
            method: 'POST',
            body: data,
        });
        const result = await response.json();
        if (result && result.success) {
            window.location.reload();
        } else {
            alert('No se pudo actualizar la tarea');
        }
    } catch (e) {
        console.error(e);
        alert('Error de red al actualizar la tarea');
    }
}
</script>
</html>
