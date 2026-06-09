<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$userId = (int)$_GET['user_id'];

try {
    // Количество подписчиков (кто подписан на пользователя)
    $stmt = $pdo->prepare("
        SELECT COUNT(*) FROM follows WHERE follow_id = ? AND status = 'accepted'
    ");
    $stmt->execute([$userId]);
    $followersCount = $stmt->fetchColumn();
    
    // Количество подписок (на кого подписан пользователь)
    $stmt = $pdo->prepare("
        SELECT COUNT(*) FROM follows WHERE user_id = ? AND status = 'accepted'
    ");
    $stmt->execute([$userId]);
    $followingCount = $stmt->fetchColumn();
    
    echo json_encode([
        'success' => true,
        'followers_count' => (int)$followersCount,
        'following_count' => (int)$followingCount
    ]);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>