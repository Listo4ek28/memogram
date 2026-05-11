<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['message_id']) || !isset($data['user_id']) || !isset($data['reason'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$validReasons = ['spam', 'advertising', 'nsfw', 'other'];
if (!in_array($data['reason'], $validReasons)) {
    echo json_encode(['error' => 'Invalid reason']);
    exit;
}

$stmt = $pdo->prepare("INSERT INTO reports (meme_id, user_id, reason, reported_at) VALUES (?, ?, ?, NOW())");
$stmt->execute([$data['message_id'], $data['user_id'], $data['reason']]);

echo json_encode(['success' => true]);
?>