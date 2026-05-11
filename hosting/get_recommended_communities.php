<?php
require_once 'config.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = (int)$_GET['user_id'];

$query = "
    SELECT c.id, c.name, c.description
    FROM communities c
    WHERE c.id NOT IN (
        SELECT community_id FROM community_subscriptions WHERE user_id = ?
    )
    ORDER BY RAND()
    LIMIT 10
";

$stmt = $pdo->prepare($query);
$stmt->execute([$user_id]);
$communities = $stmt->fetchAll();

echo json_encode(['success' => true, 'communities' => $communities]);
?>