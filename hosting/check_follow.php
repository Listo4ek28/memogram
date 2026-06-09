<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

if (!isset($_GET['user_id']) || !isset($_GET['follow_id'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit;
}

$userId = (int)$_GET['user_id'];
$followId = (int)$_GET['follow_id'];

try {
    $stmt = $pdo->prepare("
        SELECT id FROM follows 
        WHERE user_id = ? AND follow_id = ? AND status = 'accepted'
    ");
    $stmt->execute([$userId, $followId]);
    $isFollowing = $stmt->fetchColumn() ? true : false;
    
    echo json_encode([
        'success' => true,
        'is_following' => $isFollowing
    ]);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>