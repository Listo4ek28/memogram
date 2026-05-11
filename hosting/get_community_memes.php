<?php
require_once 'config.php';

if (!isset($_GET['community_id'])) {
    echo json_encode(['error' => 'Missing community_id']);
    exit;
}

$community_id = (int)$_GET['community_id'];

$query = "
    SELECT 
        m.id,
        m.user_id,
        m.meme_text,
        m.meme_image,
        m.reactions,
        m.views_count,
        m.created_at,
        u.username,
        u.avatar as user_avatar,
        (SELECT COUNT(*) FROM comments WHERE meme_id = m.id) as comments_count
    FROM memes m
    LEFT JOIN users u ON m.user_id = u.id
    WHERE m.community_id = ?
    ORDER BY m.created_at DESC
    LIMIT 100
";

$stmt = $pdo->prepare($query);
$stmt->execute([$community_id]);
$memes = $stmt->fetchAll();

echo json_encode(['success' => true, 'memes' => $memes]);
?>