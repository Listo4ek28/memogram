<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = (int)$data['user_id'];
$community_id = isset($data['community_id']) ? (int)$data['community_id'] : null;
$text = $data['text'] ?? '';
$image_base64 = $data['image'] ?? null;
$image_path = null;

// Сохраняем изображение как файл, если есть
if ($image_base64 !== null && !empty($image_base64)) {
    $image_data = base64_decode($image_base64);
    $ext = 'webp';
    $filename = uniqid() . '.' . $ext;
    $filepath = 'media/' . $filename;
    file_put_contents($filepath, $image_data);
    $image_path = 'media/' . $filename;
}

$stmt = $pdo->prepare("INSERT INTO memes (user_id, community_id, meme_text, meme_image, created_at) VALUES (?, ?, ?, ?, NOW())");
$stmt->execute([$user_id, $community_id, $text, $image_path]);

echo json_encode(['success' => true, 'message' => 'Post created', 'id' => $pdo->lastInsertId()]);
?>