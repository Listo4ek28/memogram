<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

if (!isset($_GET['user_id']) || !isset($_GET['community_id'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit;
}

$userId = (int)$_GET['user_id'];
$communityId = (int)$_GET['community_id'];

try {
    $stmt = $pdo->prepare("
        SELECT id FROM community_subscriptions 
        WHERE user_id = ? AND community_id = ?
    ");
    $stmt->execute([$userId, $communityId]);
    $isMember = $stmt->fetchColumn() ? true : false;
    
    echo json_encode([
        'success' => true,
        'is_member' => $isMember
    ]);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>