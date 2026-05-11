<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['message_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

// Удаляем только из личных сообщений пользователя
$stmt = $pdo->prepare("DELETE FROM messages WHERE id = ? AND from_user_id = ?");
$stmt->execute([$data['message_id'], $data['user_id']]);

echo json_encode(['success' => true]);
?>