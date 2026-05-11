<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id'], $data['chat_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}
if (empty($data['message_text']) && empty($data['message_image'])) {
    echo json_encode(['error' => 'Empty message']);
    exit;
}

$user_id = (int)$data['user_id'];
$chat_id = (int)$data['chat_id'];
$text = $data['message_text'] ?? '';
$image_base64 = $data['message_image'] ?? null;
$image_path = null;

// Сохраняем изображение
if ($image_base64 !== null && !empty($image_base64)) {
    $image_data = base64_decode($image_base64);
    $filename = uniqid() . '.webp';
    $filepath = 'media/' . $filename;
    file_put_contents($filepath, $image_data);
    $image_path = 'media/' . $filename;
}

$stmt = $pdo->prepare("INSERT INTO messages (from_user_id, to_user_id, message_text, message_image, created_at) VALUES (?, ?, ?, ?, NOW())");
$stmt->execute([$user_id, $chat_id, $text, $image_path]);

echo json_encode([
    'success' => true,
    'message' => [
        'id' => $pdo->lastInsertId(),
        'text' => $text,
        'image' => $image_path
    ]
]);
?>