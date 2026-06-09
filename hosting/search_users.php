<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

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
    WHERE username LIKE ? OR display_name LIKE ?
    LIMIT 20
");
$stmt->execute([$searchQuery, $searchQuery]);
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode(['success' => true, 'users' => $users]);
?>