<?php
require_once 'config.php';

// Получаем данные из запроса
$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['message_id'])) {
    echo json_encode(['error' => 'Missing fields: user_id and message_id required']);
    exit;
}

$userId = (int)$data['user_id'];
$messageId = (int)$data['message_id'];

try {
    // Проверяем, существует ли сообщение и участвует ли пользователь в диалоге
    $stmt = $pdo->prepare("
        SELECT id, from_user_id, to_user_id, message_image 
        FROM messages 
        WHERE id = ?
    ");
    $stmt->execute([$messageId]);
    $message = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$message) {
        echo json_encode(['error' => 'Message not found']);
        exit;
    }
    
    // Проверяем, что пользователь является участником диалога
    if ($message['from_user_id'] != $userId && $message['to_user_id'] != $userId) {
        echo json_encode(['error' => 'You are not a participant of this chat']);
        exit;
    }
    
    // Удаляем сообщение (без удаления медиа-файла)
    // Медиа остаётся на сервере, так как оно могло быть переслано или сохранено где-то ещё
    $deleteStmt = $pdo->prepare("DELETE FROM messages WHERE id = ?");
    $deleteStmt->execute([$messageId]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Message deleted successfully'
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        'error' => 'Database error: ' . $e->getMessage()
    ]);
}
?>