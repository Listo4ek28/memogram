<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

if (!isset($_GET['community_id'])) {
    echo json_encode(['error' => 'Missing community_id']);
    exit;
}

$communityId = (int)$_GET['community_id'];

try {
    $stmt = $pdo->prepare("
        SELECT 
            c.id,
            c.name,
            c.description,
            c.avatar,
            c.created_at,
            c.created_by,
            (SELECT COUNT(*) FROM community_subscriptions WHERE community_id = c.id) as members_count
        FROM communities c
        WHERE c.id = ?
    ");
    $stmt->execute([$communityId]);
    $community = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'community' => $community
    ]);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>