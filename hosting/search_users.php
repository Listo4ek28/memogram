<?php
require_once 'config.php';

if (!isset($_GET['q']) || !isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$query = $_GET['q'];
$user_id = (int)$_GET['user_id'];

$searchQuery = "%$query%";

$stmt = $pdo->prepare("
    SELECT id, username, display_name, avatar
    FROM users
    WHERE id != ?
    AND (username LIKE ? OR display_name LIKE ?)
    LIMIT 20
");
$stmt->execute([$user_id, $searchQuery, $searchQuery]);
$users = $stmt->fetchAll();

echo json_encode(['success' => true, 'users' => $users]);
?>