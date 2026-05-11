<?php
require_once 'config.php';

if (!isset($_GET['user_id']) || !isset($_GET['meme_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$user_id = (int)$_GET['user_id'];
$meme_id = (int)$_GET['meme_id'];

try {
    // Увеличиваем счётчик просмотров мема
    $stmt = $pdo->prepare("UPDATE memes SET views_count = views_count + 1 WHERE id = ?");
    $stmt->execute([$meme_id]);

    // Сохраняем в историю просмотров
    $stmt = $pdo->prepare("INSERT INTO view_history (user_id, meme_id, viewed_at) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE viewed_at = NOW()");
    $stmt->execute([$user_id, $meme_id]);

    // Обновляем счётчик пользователя
    $stmt = $pdo->prepare("UPDATE users SET memes_viewed = memes_viewed + 1 WHERE id = ?");
    $stmt->execute([$user_id]);

    // Получаем обновлённое количество
    $stmt = $pdo->prepare("SELECT views_count FROM memes WHERE id = ?");
    $stmt->execute([$meme_id]);
    $views = $stmt->fetchColumn();

    echo json_encode(['success' => true, 'views_count' => (int)$views]);
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>