<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$userId = (int)$_GET['user_id'];

try {
    $stmt = $pdo->prepare("
        SELECT 
            m.id,
            m.meme_text,
            m.meme_image,
            m.reactions,
            m.views_count,
            m.created_at,
            m.community_id,
            c.name as community_name
        FROM memes m
        LEFT JOIN communities c ON m.community_id = c.id
        WHERE m.user_id = ?
        ORDER BY m.created_at DESC
    ");
    $stmt->execute([$userId]);
    $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'posts' => $posts
    ]);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>