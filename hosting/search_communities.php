<?php
require_once 'config.php';

if (!isset($_GET['q'])) {
    echo json_encode(['error' => 'Missing query']);
    exit;
}

$query = $_GET['q'];
$searchQuery = "%$query%";

$stmt = $pdo->prepare("SELECT id, name, description FROM communities WHERE name LIKE ? LIMIT 10");
$stmt->execute([$searchQuery]);
$communities = $stmt->fetchAll();

echo json_encode(['success' => true, 'communities' => $communities]);
?>