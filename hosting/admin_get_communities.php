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
    $sql = "
        SELECT 
            c.id, 
            c.name, 
            c.description, 
            c.created_at,
            u.username as creator_username,
            (SELECT COUNT(*) FROM community_subscriptions WHERE community_id = c.id) as members_count,
            (SELECT COUNT(*) FROM memes WHERE community_id = c.id) as memes_count
        FROM communities c
        JOIN users u ON c.created_by = u.id
    ";
    
    if (!empty($search)) {
        $sql .= " WHERE c.name LIKE :search OR c.description LIKE :search OR u.username LIKE :search";
        $stmt = $pdo->prepare($sql . " ORDER BY c.created_at DESC");
        $stmt->execute(['search' => "%$search%"]);
    } else {
        $stmt = $pdo->prepare($sql . " ORDER BY c.created_at DESC");
        $stmt->execute();
    }
    
    $communities = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode(['success' => true, 'communities' => $communities]);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>