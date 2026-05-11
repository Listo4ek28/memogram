<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['community_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$user_id = (int)$data['user_id'];
$community_id = (int)$data['community_id'];

$stmt = $pdo->prepare("DELETE FROM community_subscriptions WHERE user_id = ? AND community_id = ?");
$stmt->execute([$user_id, $community_id]);

echo json_encode(['success' => true]);
?>