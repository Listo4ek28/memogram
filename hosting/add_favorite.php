<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['message_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

// Проверяем, не добавлен ли уже в избранное
$stmt = $pdo->prepare("SELECT id FROM favorites WHERE user_id = ? AND meme_id = ?");
$stmt->execute([$data['user_id'], $data['message_id']]);
if ($stmt->fetch()) {
    echo json_encode(['success' => true, 'message' => 'Already in favorites']);
    exit;
}

$stmt = $pdo->prepare("INSERT INTO favorites (user_id, meme_id) VALUES (?, ?)");
$stmt->execute([$data['user_id'], $data['message_id']]);

echo json_encode(['success' => true]);
?>