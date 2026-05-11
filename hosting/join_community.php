<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['community_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$user_id = (int)$data['user_id'];
$community_id = (int)$data['community_id'];

// Проверяем, не подписан ли уже
$stmt = $pdo->prepare("SELECT id FROM community_subscriptions WHERE user_id = ? AND community_id = ?");
$stmt->execute([$user_id, $community_id]);
if ($stmt->fetch()) {
    echo json_encode(['success' => false, 'error' => 'Already subscribed']);
    exit;
}

$stmt = $pdo->prepare("INSERT INTO community_subscriptions (user_id, community_id) VALUES (?, ?)");
$stmt->execute([$user_id, $community_id]);

echo json_encode(['success' => true]);
?>