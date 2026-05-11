<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['community_id']) || !isset($data['user_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$community_id = (int)$data['community_id'];
$user_id = (int)$data['user_id'];

// Проверяем, что пользователь — создатель сообщества
$stmt = $pdo->prepare("SELECT created_by FROM communities WHERE id = ?");
$stmt->execute([$community_id]);
$community = $stmt->fetch();

if (!$community) {
    echo json_encode(['error' => 'Community not found']);
    exit;
}

if ($community['created_by'] != $user_id) {
    echo json_encode(['error' => 'Only creator can delete community']);
    exit;
}

try {
    $pdo->beginTransaction();

    // Удаляем мемы сообщества
    $stmt = $pdo->prepare("DELETE FROM memes WHERE community_id = ?");
    $stmt->execute([$community_id]);

    // Удаляем подписки
    $stmt = $pdo->prepare("DELETE FROM community_subscriptions WHERE community_id = ?");
    $stmt->execute([$community_id]);

    // Удаляем само сообщество
    $stmt = $pdo->prepare("DELETE FROM communities WHERE id = ?");
    $stmt->execute([$community_id]);

    $pdo->commit();
    echo json_encode(['success' => true]);
} catch (Exception $e) {
    $pdo->rollBack();
    echo json_encode(['error' => 'Database error']);
}
?>