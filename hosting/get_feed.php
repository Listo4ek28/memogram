<?php
require_once 'config.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = (int)$_GET['user_id'];

$query = "
    SELECT 
        m.id,
        m.user_id,
        m.community_id,
        m.meme_text,
        m.meme_image,
        m.reactions,
        m.views_count,
        m.created_at,
        u.username,
        u.avatar as user_avatar,
        c.name as community_name,
        (SELECT COUNT(*) FROM comments WHERE meme_id = m.id) as comments_count
    FROM memes m
    LEFT JOIN users u ON m.user_id = u.id
    LEFT JOIN communities c ON m.community_id = c.id
    WHERE m.community_id IN (
        SELECT community_id FROM community_subscriptions WHERE user_id = ?
    )
    ORDER BY m.created_at DESC
    LIMIT 50
";

$stmt = $pdo->prepare($query);
$stmt->execute([$user_id]);
$memes = $stmt->fetchAll();

echo json_encode(['success' => true, 'memes' => $memes]);
?>