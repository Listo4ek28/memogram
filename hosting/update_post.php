<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['post_id']) || !isset($data['user_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$post_id = (int)$data['post_id'];
$user_id = (int)$data['user_id'];
$text = $data['text'] ?? '';
$image_base64 = $data['image'] ?? null;
$remove_image = $data['remove_image'] ?? false;

// Проверяем, что пост принадлежит пользователю
$stmt = $pdo->prepare("SELECT user_id, meme_image, created_at FROM memes WHERE id = ?");
$stmt->execute([$post_id]);
$post = $stmt->fetch();

if (!$post) {
    echo json_encode(['error' => 'Post not found']);
    exit;
}

if ($post['user_id'] != $user_id) {
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

// Проверяем, что прошло < 7 дней
$created = strtotime($post['created_at']);
$now = time();
if (($now - $created) > 7 * 24 * 60 * 60) {
    echo json_encode(['error' => 'Can only edit posts within 7 days']);
    exit;
}

$image_path = $post['meme_image'];

// Если нужно удалить фото
if ($remove_image) {
    // Удаляем старый файл
    if ($image_path && file_exists($image_path)) {
        unlink($image_path);
    }
    $image_path = null;
}

// Если загружено новое фото
if ($image_base64 !== null && !empty($image_base64)) {
    // Удаляем старый файл если есть
    if ($image_path && file_exists($image_path)) {
        unlink($image_path);
    }
    // Сохраняем новый
    $image_data = base64_decode($image_base64);
    $filename = uniqid() . '.webp';
    $filepath = 'media/' . $filename;
    file_put_contents($filepath, $image_data);
    $image_path = 'media/' . $filename;
}

// Обновляем пост
$stmt = $pdo->prepare("UPDATE memes SET meme_text = ?, meme_image = ? WHERE id = ?");
$stmt->execute([$text, $image_path, $post_id]);

echo json_encode([
    'success' => true,
    'post' => [
        'id' => $post_id,
        'meme_text' => $text,
        'meme_image' => $image_path
    ]
]);
?>