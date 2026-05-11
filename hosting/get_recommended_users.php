<?php
require_once 'config.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = (int)$_GET['user_id'];

$query = "
    SELECT id, username, display_name, avatar
    FROM users
    WHERE id != ?
    AND id NOT IN (
        SELECT friend_id FROM friends WHERE user_id = ?
        UNION
        SELECT user_id FROM friends WHERE friend_id = ?
    )
    ORDER BY RAND()
    LIMIT 5
";

$stmt = $pdo->prepare($query);
$stmt->execute([$user_id, $user_id, $user_id]);
$users = $stmt->fetchAll();

echo json_encode(['success' => true, 'users' => $users]);
?>