<?php
// CORS заголовки - ОБЯЗАТЕЛЬНО в самом начале!
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, X-Requested-With');
header('Content-Type: application/json');

// Обработка preflight запроса
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$search = isset($_GET['search']) ? $_GET['search'] : '';

// Проверка админа
$stmt = $pdo->prepare("SELECT admin FROM users WHERE id = ?");
$stmt->execute([$userId]);
$isAdmin = $stmt->fetchColumn();

if (!$isAdmin) {
    echo json_encode(['error' => 'Access denied']);
    exit;
}

try {
    $sql = "SELECT id, username, display_name, email, avatar, bio, memes_viewed, created_at, admin, banned FROM users";
    
    if (!empty($search)) {
        $sql .= " WHERE username LIKE :search OR display_name LIKE :search OR email LIKE :search";
        $stmt = $pdo->prepare($sql . " ORDER BY created_at DESC");
        $stmt->execute(['search' => "%$search%"]);
    } else {
        $stmt = $pdo->prepare($sql . " ORDER BY created_at DESC");
        $stmt->execute();
    }
    
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode(['success' => true, 'users' => $users]);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>