<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['message_id'])) {
    echo json_encode(['error' => 'Missing fields: user_id and message_id required']);
    exit;
}

$userId = (int)$data['user_id'];
$messageId = (int)$data['message_id'];

try {
    // Проверяем, существует ли пост и является ли пользователь его автором
    $stmt = $pdo->prepare("
        SELECT id, user_id, meme_image 
        FROM memes 
        WHERE id = ?
    ");
    $stmt->execute([$messageId]);
    $meme = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$meme) {
        echo json_encode(['error' => 'Post not found']);
        exit;
    }
    
    // Только автор может удалить свой пост
    if ($meme['user_id'] != $userId) {
        echo json_encode(['error' => 'You can only delete your own posts']);
        exit;
    }
    
    // Удаляем пост (каскадно удалятся комментарии, реакции, избранное, просмотры)
    // Медиа-файл НЕ удаляем с диска (на случай, если он используется где-то ещё)
    $deleteStmt = $pdo->prepare("DELETE FROM memes WHERE id = ? AND user_id = ?");
    $deleteStmt->execute([$messageId, $userId]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Post deleted successfully'
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        'error' => 'Database error: ' . $e->getMessage()
    ]);
}
?>