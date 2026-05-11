<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['community_id']) || !isset($data['name'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$community_id = (int)$data['community_id'];
$name = trim($data['name']);
$description = trim($data['description'] ?? '');
$avatar = $data['avatar'] ?? null;

if (empty($name)) {
    echo json_encode(['error' => 'Name cannot be empty']);
    exit;
}

// Проверяем уникальность имени
$stmt = $pdo->prepare("SELECT id FROM communities WHERE name = ? AND id != ?");
$stmt->execute([$name, $community_id]);
if ($stmt->fetch()) {
    echo json_encode(['error' => 'Community name already taken']);
    exit;
}

try {
    $stmt = $pdo->prepare("UPDATE communities SET name = ?, description = ?, avatar = ? WHERE id = ?");
    $stmt->execute([$name, $description, $avatar, $community_id]);
    echo json_encode(['success' => true]);
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error']);
}
?>