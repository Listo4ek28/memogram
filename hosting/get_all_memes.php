<?php
require_once 'config.php';

$stmt = $pdo->query("
    SELECT m.id, m.user_id, m.meme_text, m.meme_image, m.reactions, m.views_count, m.created_at,
           u.username, u.display_name, u.avatar as user_avatar
    FROM memes m
    LEFT JOIN users u ON m.user_id = u.id
    ORDER BY m.created_at DESC
    LIMIT 200
");
$memes = $stmt->fetchAll();

echo json_encode(['success' => true, 'memes' => $memes]);