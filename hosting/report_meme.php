<?php
require_once 'config.php';

header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['message_id']) || !isset($data['user_id']) || !isset($data['reason'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$messageId = (int)$data['message_id'];
$userId = (int)$data['user_id'];
$reason = $data['reason'];

try {
    // Проверяем, существует ли такой пост/сообщение и в какой таблице
    // Сначала проверяем в memes (посты)
    $stmt = $pdo->prepare("SELECT id FROM memes WHERE id = ?");
    $stmt->execute([$messageId]);
    $isPost = $stmt->fetchColumn();
    
    if ($isPost) {
        // Это пост - сохраняем в reports_posts
        $stmt = $pdo->prepare("INSERT INTO reports_posts (post_id, reporter_id, reason) VALUES (?, ?, ?)");
        $stmt->execute([$messageId, $userId, $reason]);
    } else {
        // Проверяем в messages (сообщения)
        $stmt = $pdo->prepare("SELECT id FROM messages WHERE id = ?");
        $stmt->execute([$messageId]);
        $isMessage = $stmt->fetchColumn();
        
        if ($isMessage) {
            // Это сообщение - сохраняем в reports_messages
            $stmt = $pdo->prepare("INSERT INTO reports_messages (message_id, reporter_id, reason) VALUES (?, ?, ?)");
            $stmt->execute([$messageId, $userId, $reason]);
        } else {
            echo json_encode(['error' => 'Content not found']);
            exit;
        }
    }
    
    echo json_encode(['success' => true, 'message' => 'Report submitted']);
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>