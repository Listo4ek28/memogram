<?php
require_once 'config.php';

header('Content-Type: application/json');

// Получаем параметры
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$chatId = isset($_GET['chat_id']) ? (int)$_GET['chat_id'] : 0;
$lastMessageId = isset($_GET['last_message_id']) ? (int)$_GET['last_message_id'] : 0;

if ($userId == 0 || $chatId == 0) {
    echo json_encode(['error' => 'Missing parameters']);
    exit;
}

try {
    // Проверяем, что пользователь является участником чата
    // Для личного чата chat_id - это ID собеседника
    $stmt = $pdo->prepare("
        SELECT COUNT(*) FROM messages 
        WHERE (from_user_id = ? AND to_user_id = ?) 
           OR (from_user_id = ? AND to_user_id = ?)
    ");
    $stmt->execute([$userId, $chatId, $chatId, $userId]);
    $isParticipant = $stmt->fetchColumn() > 0;
    
    // Также проверяем по последнему сообщению, если участник не найден
    if (!$isParticipant && $lastMessageId > 0) {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) FROM messages 
            WHERE id = ? AND (from_user_id = ? OR to_user_id = ?)
        ");
        $stmt->execute([$lastMessageId, $userId, $userId]);
        $isParticipant = $stmt->fetchColumn() > 0;
    }
    
    if (!$isParticipant && $lastMessageId == 0) {
        echo json_encode(['error' => 'You are not a participant of this chat']);
        exit;
    }
    
    // Получаем новые сообщения (с ID больше last_message_id)
    // и сообщения, которые пользователь ещё не видел (is_read = 0 для получателя)
    $stmt = $pdo->prepare("
        SELECT 
            m.id,
            m.from_user_id,
            m.to_user_id,
            m.message_text,
            m.message_image,
            m.is_read,
            m.created_at,
            u.display_name,
            u.username,
            u.avatar
        FROM messages m
        LEFT JOIN users u ON m.from_user_id = u.id
        WHERE (
            (m.from_user_id = ? AND m.to_user_id = ?)
            OR (m.from_user_id = ? AND m.to_user_id = ?)
        )
        AND m.id > ?
        ORDER BY m.created_at ASC
        LIMIT 50
    ");
    $stmt->execute([$userId, $chatId, $chatId, $userId, $lastMessageId]);
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Если есть новые сообщения, помечаем их как прочитанные (для получателя)
    if (!empty($messages)) {
        $messageIds = array_column($messages, 'id');
        $placeholders = implode(',', array_fill(0, count($messageIds), '?'));
        $updateStmt = $pdo->prepare("
            UPDATE messages 
            SET is_read = 1 
            WHERE id IN ($placeholders) 
            AND to_user_id = ?
        ");
        $params = array_merge($messageIds, [$userId]);
        $updateStmt->execute($params);
    }
    
    // Форматируем сообщения для клиента
    $formattedMessages = [];
    foreach ($messages as $msg) {
        $isSent = ($msg['from_user_id'] == $userId);
        $formattedMessages[] = [
            'message_id' => (int)$msg['id'],
            'type' => $isSent ? 'sent' : 'received',
            'text' => $msg['message_text'],
            'image' => $msg['message_image'],
            'from_user' => (int)$msg['from_user_id'],
            'display_name' => $msg['display_name'] ?? $msg['username'],
            'avatar' => $msg['avatar'],
            'time' => date('H:i', strtotime($msg['created_at'])),
            'created_at' => $msg['created_at']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'messages' => $formattedMessages,
        'has_new' => !empty($formattedMessages)
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        'error' => 'Database error: ' . $e->getMessage()
    ]);
}
?>