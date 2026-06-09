<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$communityId = isset($_GET['community_id']) ? (int)$_GET['community_id'] : 0;

// Проверка админа
$stmt = $pdo->prepare("SELECT admin FROM users WHERE id = ?");
$stmt->execute([$userId]);
$isAdmin = $stmt->fetchColumn();

if (!$isAdmin) {
    echo json_encode(['error' => 'Access denied']);
    exit;
}

if ($communityId == 0) {
    echo json_encode(['error' => 'Community ID required']);
    exit;
}

try {
    $stmt = $pdo->prepare("
        SELECT 
            m.id,
            m.meme_text,
            m.meme_image,
            m.reactions,
            m.views_count,
            m.created_at,
            u.id as user_id,
            u.username,
            u.display_name,
            u.banned as user_banned
        FROM memes m
        JOIN users u ON m.user_id = u.id
        WHERE m.community_id = ?
        ORDER BY m.created_at DESC
        LIMIT 100
    ");
    $stmt->execute([$communityId]);
    $memes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($memes as &$meme) {
        $meme['meme_image_url'] = $meme['meme_image'] ? 'https://listo4ek.tech/' . $meme['meme_image'] : null;
        $meme['meme_text'] = $meme['meme_text'] ?? '[No text]';
        $meme['reactions'] = (int)($meme['reactions'] ?? 0);
        $meme['views_count'] = (int)($meme['views_count'] ?? 0);
        $meme['user_banned'] = (int)($meme['user_banned'] ?? 0);
    }
    
    echo json_encode([
        'success' => true,
        'memes' => $memes,
        'community_id' => $communityId
    ]);
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>