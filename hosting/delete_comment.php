<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['comment_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$userId = (int)$data['user_id'];
$commentId = (int)$data['comment_id'];

try {
    // Проверяем, принадлежит ли комментарий пользователю
    $stmt = $pdo->prepare("SELECT user_id FROM comments WHERE id = ?");
    $stmt->execute([$commentId]);
    $commentOwner = $stmt->fetchColumn();
    
    if ($commentOwner != $userId) {
        echo json_encode(['error' => 'You can only delete your own comments']);
        exit;
    }
    
    $stmt = $pdo->prepare("DELETE FROM comments WHERE id = ?");
    $stmt->execute([$commentId]);
    
    echo json_encode(['success' => true, 'message' => 'Comment deleted']);
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>