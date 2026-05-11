<?php
require_once 'config.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = (int)$_GET['user_id'];

$query = "
    SELECT u.id, u.username, u.display_name, u.avatar
    FROM users u
    INNER JOIN friends f ON (f.user_id = ? AND f.friend_id = u.id) OR (f.friend_id = ? AND f.user_id = u.id)
    WHERE f.status = 'accepted'
";

$stmt = $pdo->prepare($query);
$stmt->execute([$user_id, $user_id]);
$friends = $stmt->fetchAll();

echo json_encode(['success' => true, 'friends' => $friends]);
?>