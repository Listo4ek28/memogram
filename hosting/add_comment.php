<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['meme_id']) || !isset($data['comment_text'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$user_id = (int)$data['user_id'];
$meme_id = (int)$data['meme_id'];
$comment_text = trim($data['comment_text']);

if (empty($comment_text)) {
    echo json_encode(['error' => 'Empty comment']);
    exit;
}

try {
    // Проверяем, существует ли мем
    $stmt = $pdo->prepare("SELECT id FROM memes WHERE id = ?");
    $stmt->execute([$meme_id]);
    if (!$stmt->fetch()) {
        echo json_encode(['error' => 'Post not found']);
        exit;
    }

    // Добавляем комментарий
    $stmt = $pdo->prepare("INSERT INTO comments (user_id, meme_id, comment_text, created_at) VALUES (?, ?, ?, NOW())");
    $stmt->execute([$user_id, $meme_id, $comment_text]);
    $comment_id = $pdo->lastInsertId();

    // Получаем данные добавленного комментария
    $stmt = $pdo->prepare("
        SELECT c.id, c.user_id, c.comment_text, c.created_at,
               u.username, u.display_name, u.avatar
        FROM comments c
        LEFT JOIN users u ON c.user_id = u.id
        WHERE c.id = ?
    ");
    $stmt->execute([$comment_id]);
    $comment = $stmt->fetch();

    echo json_encode(['success' => true, 'comment' => $comment]);
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error']);
}
?>