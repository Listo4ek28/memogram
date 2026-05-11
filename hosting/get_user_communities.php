<?php
require_once 'config.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = (int)$_GET['user_id'];

$query = "
    SELECT c.id, c.name, c.description, c.avatar, c.created_by
    FROM communities c
    INNER JOIN community_subscriptions cs ON c.id = cs.community_id
    WHERE cs.user_id = ?
    ORDER BY c.name
";

$stmt = $pdo->prepare($query);
$stmt->execute([$user_id]);
$communities = $stmt->fetchAll();

echo json_encode(['success' => true, 'communities' => $communities]);
?>