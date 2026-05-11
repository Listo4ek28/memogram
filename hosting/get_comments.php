<?php
require_once 'config.php';

header('Content-Type: application/json; charset=utf-8');

if (!isset($_GET['meme_id'])) {
    echo json_encode(['error' => 'Missing meme_id']);
    exit;
}

$meme_id = (int)$_GET['meme_id'];
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 5;
$offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

// Получаем комментарии
$stmt = $pdo->prepare("
    SELECT c.id, c.user_id, c.comment_text, c.created_at,
           u.username, u.display_name, u.avatar
    FROM comments c
    LEFT JOIN users u ON c.user_id = u.id
    WHERE c.meme_id = ?
    ORDER BY c.created_at ASC
    LIMIT ? OFFSET ?
");
$stmt->bindValue(1, $meme_id, PDO::PARAM_INT);
$stmt->bindValue(2, $limit, PDO::PARAM_INT);
$stmt->bindValue(3, $offset, PDO::PARAM_INT);
$stmt->execute();
$comments = $stmt->fetchAll();

// Общее количество
$stmt = $pdo->prepare("SELECT COUNT(*) FROM comments WHERE meme_id = ?");
$stmt->execute([$meme_id]);
$total = $stmt->fetchColumn();

echo json_encode([
    'success' => true,
    'comments' => $comments,
    'total' => (int)$total
]);
?>