<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['name'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$user_id = (int)$data['user_id'];
$name = trim($data['name']);
$description = trim($data['description'] ?? '');
$avatar = $data['avatar'] ?? null;

if (empty($name)) {
    echo json_encode(['error' => 'Name cannot be empty']);
    exit;
}

// Проверяем, нет ли уже такого сообщества
$stmt = $pdo->prepare("SELECT id FROM communities WHERE name = ?");
$stmt->execute([$name]);
if ($stmt->fetch()) {
    echo json_encode(['error' => 'Community already exists']);
    exit;
}

try {
    $stmt = $pdo->prepare("INSERT INTO communities (name, description, avatar, created_by, created_at) VALUES (?, ?, ?, ?, NOW())");
    $stmt->execute([$name, $description, $avatar, $user_id]);
    $community_id = $pdo->lastInsertId();

    // Автоматически подписываем создателя
    $stmt = $pdo->prepare("INSERT IGNORE INTO community_subscriptions (user_id, community_id) VALUES (?, ?)");
    $stmt->execute([$user_id, $community_id]);

    echo json_encode([
        'success' => true,
        'community' => [
            'id' => $community_id,
            'name' => $name,
            'description' => $description,
            'avatar' => $avatar
        ]
    ]);
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error']);
}
?>